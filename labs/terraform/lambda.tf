# -----------------------------------------------------------------------------
# Lambda deployment packages
# -----------------------------------------------------------------------------

data "archive_file" "data_generator" {
  type        = "zip"
  output_path = "${path.module}/data_generator.zip"

  source {
    content  = file("${path.module}/../data_generator/generator.py")
    filename = "generator.py"
  }
  source {
    content  = file("${path.module}/../data_generator/trades.csv")
    filename = "trades.csv"
  }
}

data "archive_file" "data_reader" {
  type        = "zip"
  output_path = "${path.module}/data_reader.zip"

  source {
    content  = file("${path.module}/../data_reader/reader.py")
    filename = "reader.py"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch log groups for Lambda
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "data_generator" {
  name              = "/aws/lambda/data-generator-${local.identifier}"
  retention_in_days  = 7
}

resource "aws_cloudwatch_log_group" "data_reader" {
  name              = "/aws/lambda/data-reader-${local.identifier}"
  retention_in_days  = 7
}

# -----------------------------------------------------------------------------
# Lambda functions (using var.lab_role_arn)
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "data_generator" {
  filename         = data.archive_file.data_generator.output_path
  function_name    = "data-generator-${local.identifier}"
  role             = var.lab_role_arn
  handler          = "generator.lambda_handler"
  source_code_hash = data.archive_file.data_generator.output_base64sha256
  runtime          = "python3.12"

  environment {
    variables = {
      KINESIS_STREAM_NAME = aws_kinesis_stream.main.name
    }
  }

  timeout = 60
}

resource "aws_lambda_function" "data_reader" {
  filename         = data.archive_file.data_reader.output_path
  function_name    = "data-reader-${local.identifier}"
  role             = var.lab_role_arn
  handler          = "reader.lambda_handler"
  source_code_hash = data.archive_file.data_reader.output_base64sha256
  runtime          = "python3.12"

  timeout = 60
}

# -----------------------------------------------------------------------------
# Kinesis event source mapping - data_reader consumes from Kinesis
# -----------------------------------------------------------------------------

resource "aws_lambda_event_source_mapping" "data_reader_kinesis" {
  event_source_arn  = aws_kinesis_stream.main.arn
  function_name     = aws_lambda_function.data_reader.arn
  starting_position = "LATEST"
  batch_size        = 10
}

# -----------------------------------------------------------------------------
# Invoke data_generator with 100 events in 10 threads, wait for result
# -----------------------------------------------------------------------------

resource "aws_lambda_invocation" "data_generator" {
  function_name = aws_lambda_function.data_generator.function_name

  input = jsonencode({
    transactions   = 100
    threads        = 10
    kinesis_stream = aws_kinesis_stream.main.name
  })

  triggers = {
    redeployment = data.archive_file.data_generator.output_base64sha256
  }

  depends_on = [
    aws_lambda_function.data_generator,
    aws_lambda_event_source_mapping.data_reader_kinesis
  ]
}

output "data_generator_invocation_result" {
  description = "Result of data_generator Lambda invocation (100 events, 10 threads)"
  value       = jsondecode(aws_lambda_invocation.data_generator.result)
}
