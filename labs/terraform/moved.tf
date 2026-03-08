# -----------------------------------------------------------------------------
# Moved blocks - refactor resources into lambda module
# Run: terraform plan -generate-config-out=generated.tf (optional, for verification)
# -----------------------------------------------------------------------------

# data_generator
moved {
  from = aws_lambda_function.data_generator
  to   = module.lambda_data_generator.aws_lambda_function.this
}

moved {
  from = aws_cloudwatch_log_group.data_generator
  to   = module.lambda_data_generator.aws_cloudwatch_log_group.this
}

# data_reader
moved {
  from = aws_lambda_function.data_reader
  to   = module.lambda_data_reader.aws_lambda_function.this
}

moved {
  from = aws_cloudwatch_log_group.data_reader
  to   = module.lambda_data_reader.aws_cloudwatch_log_group.this
}

# firehose_validator
moved {
  from = aws_lambda_function.firehose_validator
  to   = module.lambda_firehose_validator.aws_lambda_function.this
}

moved {
  from = aws_cloudwatch_log_group.firehose_validator
  to   = module.lambda_firehose_validator.aws_cloudwatch_log_group.this
}

# invalid_producer
moved {
  from = aws_lambda_function.invalid_producer
  to   = module.lambda_invalid_producer.aws_lambda_function.this
}

moved {
  from = aws_cloudwatch_log_group.invalid_producer
  to   = module.lambda_invalid_producer.aws_cloudwatch_log_group.this
}
