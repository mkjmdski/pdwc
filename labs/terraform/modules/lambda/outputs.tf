output "arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.this.arn
}

output "function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.this.function_name
}

output "invoke_arn" {
  description = "Lambda invoke ARN"
  value       = aws_lambda_function.this.invoke_arn
}

output "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package"
  value       = data.archive_file.lambda.output_base64sha256
}
