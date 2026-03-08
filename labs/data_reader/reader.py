#!/usr/bin/env python3
"""
Kinesis consumer Lambda - displays events sent by data_generator.
Triggered by Kinesis event source mapping.
"""
import base64
import json
import logging

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s - %(message)s',
)
logger = logging.getLogger(__name__)


def lambda_handler(event, context=None):
    """
    Process Kinesis records. Each record contains base64-encoded JSON from data_generator.
    """
    records = event.get('Records', [])
    logger.info('Received {} records from Kinesis'.format(len(records)))

    for record in records:
        try:
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            # Data may have trailing newline from producer
            payload = payload.strip()
            event_data = json.loads(payload)
            logger.info('Event: trans_id={} symbol={} price={} amount={} type={}'.format(
                event_data.get('trans_id'),
                event_data.get('symbol'),
                event_data.get('price'),
                event_data.get('amount'),
                event_data.get('type'),
            ))
            logger.info('Full event: {}'.format(json.dumps(event_data)))
        except Exception as e:
            logger.error('Failed to process record: {}'.format(e))
            raise

    return {'statusCode': 200, 'processed': len(records)}
