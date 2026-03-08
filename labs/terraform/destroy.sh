#!/usr/bin/env bash
# Destroy resources that incur ongoing costs: Kinesis, Firehose, S3.
# Lambdas, CloudWatch, IAM stay (minimal/no cost when idle).
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Destroying cost-incurring resources (Kinesis, Firehose, S3)..."

# Order matters: destroy dependents before dependencies
terraform destroy \
  -target=aws_lambda_event_source_mapping.data_reader_kinesis \
  -target=aws_lambda_permission.allow_firehose_validator \
  -target=aws_kinesis_firehose_delivery_stream.main \
  -target=aws_kinesis_stream.main \
  -target='aws_s3_bucket.landings["raw"]' \
  -target='aws_s3_bucket.landings["processed"]' \
  -auto-approve

echo "Done. Lambdas and CloudWatch log groups remain."
