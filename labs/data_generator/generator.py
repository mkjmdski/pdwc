#!/usr/bin/env python3
import argparse
import csv
import json
import logging
import os
import random
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import boto3

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] {%(filename)s:%(lineno)d} %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

DEFAULT_DATA_FILE = 'trades.csv'
DEFAULT_THREADS = 10


class KinesisProducer:
    """
    Kinesis Producer
    """

    def __init__(self, speed_per_sec):

        self.client = boto3.client('kinesis')
        self.max_retry_attempt = 5

    def produce(self, event, key, data_stream, log_success=False):
        """
        A simple wrapper for put record
        :param event:
        :param key:
        :param data_stream:
        :param log_success: if True, log each successful send (verbose)
        :return:
        """
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
                if log_success:
                    logger.info('Msg with trans_id={} sent to shard {} seq no {}'.format(
                        tran_id, response["ShardId"], response["SequenceNumber"]))
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


def _send_chunk(args):
    """Worker: send a chunk of rows to Kinesis. Returns (sent_count, error_count)."""
    rows, data_stream = args
    kp = KinesisProducer(speed_per_sec=-1)
    sent, errors = 0, 0
    for row in rows:
        try:
            event, key = prepare_event(row)
            kp.produce(event, key, data_stream, log_success=False)
            sent += 1
        except Exception as e:
            logger.warning('Failed to send trans_id={}: {}'.format(row.get("trans_id"), e))
            errors += 1
    return sent, errors


def produce_data_parallel(kinesis_data_stream, input_file, num_transactions, num_threads):
    """
    Send transactions to Kinesis in parallel using multiple threads.
    Suitable for Lambda: bounded workload, fast completion.
    """
    with open(input_file) as csv_file:
        reader = csv.DictReader(csv_file, delimiter=',')
        all_rows = list(reader)

    if not all_rows:
        logger.warning('CSV file is empty')
        return

    # Sample transactions randomly (with replacement, so we always get exactly num_transactions)
    rows_to_send = random.choices(all_rows, k=num_transactions)

    # Split into chunks for each thread
    chunk_size = max(1, (len(rows_to_send) + num_threads - 1) // num_threads)
    chunks = [
        (rows_to_send[i:i + chunk_size], kinesis_data_stream)
        for i in range(0, len(rows_to_send), chunk_size)
    ]

    logger.info('Sending {} transactions using {} threads ({} chunks)'.format(
        len(rows_to_send), num_threads, len(chunks)))

    start = time.time()
    total_sent, total_errors = 0, 0

    with ThreadPoolExecutor(max_workers=num_threads) as executor:
        futures = [executor.submit(_send_chunk, chunk) for chunk in chunks]
        for future in as_completed(futures):
            sent, errors = future.result()
            total_sent += sent
            total_errors += errors

    elapsed = time.time() - start
    logger.info('Done: {} sent, {} errors in {:.2f}s ({:.0f} tx/s)'.format(
        total_sent, total_errors, elapsed, total_sent / elapsed if elapsed > 0 else 0))


def lambda_handler(event, context=None):
    """
    Lambda entry point. Expects event like:
    {"transactions": 1000, "threads": 10, "kinesis_stream": "my-stream"}
    kinesis_stream can also come from env KINESIS_STREAM_NAME.
    """
    num_transactions = int(event.get('transactions', 1000))
    num_threads = int(event.get('threads', DEFAULT_THREADS))
    kinesis_stream = event.get('kinesis_stream') or os.environ.get('KINESIS_STREAM_NAME')
    if not kinesis_stream:
        raise ValueError('kinesis_stream required in event or KINESIS_STREAM_NAME in env')

    main_path = os.path.abspath(os.path.dirname(__file__))
    input_file = os.path.join(main_path, DEFAULT_DATA_FILE)

    produce_data_parallel(kinesis_stream, input_file, num_transactions, num_threads)
    return {'statusCode': 200, 'body': {'transactions': num_transactions, 'threads': num_threads}}


if __name__ == "__main__":
    logger.info('Starting Kinesis Producer (parallel mode)')

    parser = argparse.ArgumentParser()
    parser.add_argument('-k', '--kinesis_ds', dest='kinesis_ds', required=True)
    parser.add_argument('-i', '--input_file', dest='input_file', required=False)
    parser.add_argument('-n', '--transactions', dest='transactions', type=int, required=True,
                        help='Number of transactions to send')

    parser.add_argument('-t', '--threads', dest='threads', type=int, default=DEFAULT_THREADS,
                        help='Number of worker threads (default: 10)')

    args = parser.parse_args()

    kinesis_data_stream = args.kinesis_ds
    num_transactions = args.transactions
    num_threads = args.threads

    if args.input_file:
        input_file = args.input_file
    else:
        main_path = os.path.abspath(os.path.dirname(__file__))
        input_file = os.path.join(main_path, DEFAULT_DATA_FILE)

    produce_data_parallel(kinesis_data_stream, input_file, num_transactions, num_threads)
