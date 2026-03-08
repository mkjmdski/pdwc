#!/usr/bin/env python3
"""
Firehose transformation Lambda - validates records before delivery to S3.
Records failing validation are marked ProcessingFailed and routed to error_output_prefix.
"""
import base64
import json
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

REQUIRED_FIELDS = ["transaction_ts", "symbol", "price", "amount", "dollar_amount", "type", "trans_id"]


def validate_record(record: dict) -> tuple[bool, str]:
    """
    Validate a trade record. Returns (is_valid, error_message).
    """
    for field in REQUIRED_FIELDS:
        if field not in record:
            return False, f"Missing required field: {field}"

    try:
        int(record["transaction_ts"])
        float(record["price"])
        float(record["amount"])
        float(record["dollar_amount"])
        int(record["trans_id"])
    except (ValueError, TypeError) as e:
        return False, f"Invalid type: {e}"

    if record["price"] <= 0 or record["amount"] <= 0:
        return False, "price and amount must be positive"

    return True, ""


def lambda_handler(event, context=None):
    """
    Firehose transformation handler. Validates each record.
    Returns Ok for valid records, ProcessingFailed for invalid.
    """
    records = event.get("records", [])
    logger.info("Processing %d records", len(records))
    output = []

    for record in records:
        record_id = record["recordId"]
        data = base64.b64decode(record["data"]).decode("utf-8").strip()

        try:
            payload = json.loads(data)
        except json.JSONDecodeError as e:
            output.append({
                "recordId": record_id,
                "result": "ProcessingFailed",
                "data": record["data"],
            })
            logger.warning("Invalid JSON for record %s: %s", record_id, e)
            continue

        valid, error = validate_record(payload)
        if valid:
            output.append({
                "recordId": record_id,
                "result": "Ok",
                "data": record["data"],
            })
        else:
            output.append({
                "recordId": record_id,
                "result": "ProcessingFailed",
                "data": record["data"],
            })
            logger.warning("Validation failed for record %s: %s", record_id, error)

    return {"records": output}
