resource "aws_kinesis_stream" "main" {
  name                      = "cryptostock-${local.identifier}"
  shard_count               = 1
  retention_period          = 24
  enforce_consumer_deletion = true
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords",
  ]
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}

resource "aws_lambda_permission" "allow_firehose_validator" {
  statement_id  = "AllowExecutionFromFirehose"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_firehose_validator.function_name
  principal     = "firehose.amazonaws.com"
  source_arn    = aws_kinesis_firehose_delivery_stream.main.arn
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "test-firehose-${local.identifier}"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.main.arn
    role_arn           = var.lab_role_arn
  }

  extended_s3_configuration {
    role_arn   = var.lab_role_arn
    bucket_arn = aws_s3_bucket.landings["raw"].arn

    prefix = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"

    error_output_prefix = "errors/type=!{firehose:error-output-type}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"

    processing_configuration {
      enabled = true

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${module.lambda_firehose_validator.arn}:$LATEST"
        }
        parameters {
          parameter_name  = "RoleArn"
          parameter_value = var.lab_role_arn
        }
      }
    }
  }
}
