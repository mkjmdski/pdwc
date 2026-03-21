# -----------------------------------------------------------------------------
# Lambda functions (using lambda module)
# -----------------------------------------------------------------------------

module "lambda_data_generator" {
  source = "./modules/lambda"

  name     = "data-generator-${local.identifier}"
  role_arn = var.lab_role_arn
  handler  = "generator.lambda_handler"

  source_files = [
    "../data_generator/generator.py",
    "../data_generator/trades.csv",
  ]

  environment = {
    KINESIS_STREAM_NAME    = aws_kinesis_stream.main.name
    GENERATOR_THREADS      = tostring(var.generator_threads)
    GENERATOR_TRANSACTIONS = tostring(var.generator_transactions)
  }

  memory_size = 512
  timeout     = 60
}

module "lambda_data_reader" {
  source = "./modules/lambda"

  name     = "data-reader-${local.identifier}"
  role_arn = var.lab_role_arn
  handler  = "reader.lambda_handler"

  source_files = [
    "../data_reader/reader.py",
  ]
}

module "lambda_firehose_validator" {
  source = "./modules/lambda"

  name     = "firehose-validator-${local.identifier}"
  role_arn = var.lab_role_arn
  handler  = "validator.lambda_handler"

  source_files = [
    "../data_validator/validator.py",
  ]

  timeout = 60
}

module "lambda_invalid_producer" {
  source = "./modules/lambda"

  name     = "invalid-producer-${local.identifier}"
  role_arn = var.lab_role_arn
  handler  = "invalid_producer.lambda_handler"

  source_files = [
    "../data_generator/invalid_producer.py",
  ]

  environment = {
    KINESIS_STREAM_NAME = aws_kinesis_stream.main.name
  }

  timeout = 30
}

# -----------------------------------------------------------------------------
# EventBridge schedule - run data_generator every 1 minute
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "data_generator_schedule" {
  name                = "data-generator-schedule-${local.identifier}"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "data_generator" {
  rule     = aws_cloudwatch_event_rule.data_generator_schedule.name
  arn      = module.lambda_data_generator.arn
  role_arn = var.lab_role_arn
}

# -----------------------------------------------------------------------------
# Kinesis event source mapping - data_reader consumes from Kinesis
# -----------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "data_reader_kinesis" {
  event_source_arn  = aws_kinesis_stream.main.arn
  function_name     = module.lambda_data_reader.arn
  starting_position = "LATEST"
  batch_size        = 10
}

# -----------------------------------------------------------------------------
# Invoke data_generator
# -----------------------------------------------------------------------------

resource "aws_lambda_invocation" "data_generator" {
  function_name = module.lambda_data_generator.function_name

  input = jsonencode({})

  triggers = {
    redeployment = module.lambda_data_generator.source_code_hash
    config       = "${var.generator_threads}-${var.generator_transactions}"
  }

  depends_on = [
    module.lambda_data_generator,
    aws_lambda_event_source_mapping.data_reader_kinesis
  ]
}

resource "aws_lambda_invocation" "invalid_producer" {
  function_name = module.lambda_invalid_producer.function_name

  input = jsonencode({
    kinesis_stream = aws_kinesis_stream.main.name
  })

  triggers = {
    redeployment = module.lambda_invalid_producer.source_code_hash
  }

  depends_on = [
    aws_lambda_invocation.data_generator
  ]
}

# output "data_generator_invocation_result" {
#   description = "Result of data_generator Lambda invocation"
#   value       = jsondecode(aws_lambda_invocation.data_generator.result)
# }

# output "invalid_producer_invocation_result" {
#   description = "Result of invalid_producer Lambda (5 invalid messages sent to test validator)"
#   value       = jsondecode(aws_lambda_invocation.invalid_producer.result)
# }
