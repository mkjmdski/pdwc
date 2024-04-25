#!/usr/bin/env python3
import configparser
import argparse

import csv
import time
import logging
import sys
import json
import os

import boto3

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

DEFAULT_DATA_FILE = 'crypto_trades_20201001.csv'


class KinesisProducer:
    """
    Kinesis Producer
    """

    def __init__(self, speed_per_sec):

        self.client = boto3.client('kinesis')
        self.max_retry_attempt = 5

    def produce(self, event, key, data_stream):
        """
        A simple wrapper for put record
        :param event:
        :param key:
        :param data_stream:
        :return:
        """

        # adding a new line at the end to produce JSON lines
        # (otherwise we would need to pre-process those records in Firehose
        # invoking a Lambda to add those new lines).Every message is a dumped json with \n

        tran_id = event["trans_id"]
        payload = (json.dumps(event) + '\n').encode('utf-8')

        attempt = 1
        while attempt < self.max_retry_attempt:
            try:
                response = self.client.put_record(
                    StreamName=data_stream,
                    Data=payload,
                    PartitionKey=key
                )
                logger.info('Msg with trans_id={} sent to shard {} seq no {}'.format(tran_id, response["ShardId"],
                                                                                     response["SequenceNumber"]))
                return response

            except Exception as e:
                logger.warning('Exception has occurred {}, retrying...'.format(e))
                attempt += 1
                time.sleep(attempt)

        logger.error('Max attempt has been reached, rethrowing the last err')
        raise


def prepare_event(event):
    """
    Events from CSV have no dtypes, lets convert it to some more real values (int / decimals etc)
    :param event:
    :return:
    """
    msg_key = event["symbol"]

    msg_formatted = {
        "transaction_ts": int(event["transaction_ts"]),
        "symbol": event["symbol"],
        "price": float(event["price"]),
        "amount": float(event["amount"]),
        "dollar_amount": float(event["dollar_amount"]),
        "type": event["type"],
        "trans_id": int(event["trans_id"]),
    }

    return msg_formatted, msg_key


def produce_data(kinesis_data_stream, messages_per_sec, input_file, single_run):
    """
    Main method for producing
    :param kinesis_data_stream: param from cmdline name of KDS
    :param messages_per_sec: param from cmdline max speed per sec 1/mps
    :return:
    """
    kp = KinesisProducer(speed_per_sec=messages_per_sec)

    with open(input_file) as csv_file:
        reader = csv.DictReader(csv_file, delimiter=',')
        all_rows = list(reader)

    current_time = int(all_rows[0]["transaction_ts"])

    replay_cnt = 1
    while True:
        logger.info("start replaying for the {} time".format(replay_cnt))
        for row in all_rows:

            new_event_time = int(row["transaction_ts"])
            time_delta = new_event_time - current_time
            current_time = new_event_time

            if time_delta > 0 and messages_per_sec > 0:
                time.sleep(time_delta / messages_per_sec)

            event, key = prepare_event(row)
            kp.produce(event, key, kinesis_data_stream)

        if single_run:
            break
        replay_cnt += 1


if __name__ == "__main__":
    logger.info('Starting Simple Kinesis Producer (replaying stock data)')

    parser = argparse.ArgumentParser()
    parser.add_argument('-k', '--kinesis_ds', dest='kinesis_ds', required=True)
    parser.add_argument('-i', '--input_file', dest='input_file', required=False)
    parser.add_argument('-s', '--messages_per_sec', dest='mps', type=int, default=-1, required=False)
    parser.add_argument('-r', '--single-run', dest='singel_run', action='store_true', required=False, default=False)

    args, unknown = parser.parse_known_args()
    config = configparser.ConfigParser()

    kinesis_data_stream = args.kinesis_ds
    messages_per_sec = int(args.mps)

    single_run = args.singel_run if hasattr(args, 'singel_run') else False

    if args.input_file:
        input_file = args.input_file
    else:
        main_path = os.path.abspath(os.path.dirname(__file__))
        input_file = os.path.join(main_path, DEFAULT_DATA_FILE)

    produce_data(kinesis_data_stream, messages_per_sec, input_file, single_run)
