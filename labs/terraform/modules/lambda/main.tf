# -----------------------------------------------------------------------------
# Archive
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.root}/${var.name}.zip"

  dynamic "source" {
    for_each = var.source_files
    content {
      content  = file("${path.root}/${source.value}")
      filename = regex("[^/]+$", source.value)
    }
  }
}

# -----------------------------------------------------------------------------
# Lambda function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.name
  role             = var.role_arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = merge(var.environment, {
      PYTHONUNBUFFERED = "1"
    })
  }

  logging_config {
    application_log_level = "INFO"
    log_format           = "Text"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch log group
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.log_retention_days
}
