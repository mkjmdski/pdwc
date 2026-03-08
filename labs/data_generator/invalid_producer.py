#!/usr/bin/env python3
"""
Lambda that sends 5 invalid messages to Kinesis to test the Firehose validator.
Each message is designed to fail a different validation rule.
"""
import json
import logging
import os
import sys

import boto3

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# 5 invalid messages - each fails a different validation rule
INVALID_MESSAGES = [
    # 1. Missing required field: symbol
    {"transaction_ts": 1601510403, "price": 360.03, "amount": 0.646, "dollar_amount": 232.57, "type": "buy", "trans_id": 999001},
    # 2. Invalid type: price as string
    {"transaction_ts": 1601510404, "symbol": "ETH_USD", "price": "not_a_number", "amount": 0.5, "dollar_amount": 180.0, "type": "buy", "trans_id": 999002},
    # 3. Negative price
    {"transaction_ts": 1601510405, "symbol": "BTC_USD", "price": -100.0, "amount": 0.1, "dollar_amount": -10.0, "type": "sell", "trans_id": 999003},
    # 4. Missing trans_id
    {"transaction_ts": 1601510406, "symbol": "ETH_USD", "price": 361.0, "amount": 1.0, "dollar_amount": 361.0, "type": "buy"},
    # 5. Malformed - not valid JSON (will be sent as raw string to trigger JSON decode error)
    "this is not json at all",
]


def lambda_handler(event, context=None):
    """
    Send 5 invalid messages to Kinesis to test the validator.
    Expects kinesis_stream in event or KINESIS_STREAM_NAME in env.
    """
    kinesis_stream = event.get("kinesis_stream") or os.environ.get("KINESIS_STREAM_NAME")
    if not kinesis_stream:
        raise ValueError("kinesis_stream required in event or KINESIS_STREAM_NAME in env")

    logger.info("Sending 5 invalid messages to Kinesis stream: %s", kinesis_stream)
    client = boto3.client("kinesis")
    sent = []

    for i, msg in enumerate(INVALID_MESSAGES):
        if isinstance(msg, dict):
            payload = json.dumps(msg)
        else:
            payload = str(msg)

        payload_bytes = (payload + "\n").encode("utf-8")
        partition_key = msg.get("symbol", "invalid") if isinstance(msg, dict) else "invalid"

        try:
            client.put_record(
                StreamName=kinesis_stream,
                Data=payload_bytes,
                PartitionKey=partition_key,
            )
            sent.append({"index": i + 1, "payload": payload[:80]})
            logger.info("Sent invalid message %d: %s", i + 1, payload[:80])
        except Exception as e:
            logger.error("Failed to send message %d: %s", i + 1, e)
            raise

    return {
        "statusCode": 200,
        "body": {"sent": len(sent), "messages": sent},
    }
