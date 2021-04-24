resource "aws_lambda_layer_version" "aws_wrangler" {
  filename = "../lambda/awswrangler-layer-2.7.0-py3.8.zip"
  layer_name = "aws_wrangler_${var.environment}_${var.account_number}_${var.student_initials}_${var.student_index_no}"
  source_code_hash = "${filebase64sha256("../lambda/awswrangler-layer-2.7.0-py3.8.zip")}"
  compatible_runtimes = [
    "python3.8"]
}


resource "aws_lambda_function" "etl_post_processing" {

  function_name = "etl-post-processing-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  filename = "../lambda/lambda_definition.zip"
  handler = "lambda_definition.etl_function"
  runtime = "python3.8"
  role = aws_iam_role.lambda_basic_role.arn
  timeout = 300
  memory_size = 512
  source_code_hash = filebase64sha256("../lambda/lambda_definition.zip")
  layers = [
    "${aws_lambda_layer_version.aws_wrangler.arn}"]

}


resource "aws_lambda_permission" "allow_bucket" {
  statement_id = "AllowExecutionFromS3Bucket"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.etl_post_processing.arn
  principal = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.main_dl_bucket.arn
}


resource "aws_s3_bucket_notification" "trigger_etl_lambda" {
  bucket = aws_s3_bucket.main_dl_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.etl_post_processing.arn
    events = [
      "s3:ObjectCreated:*"]
    filter_prefix = "raw-zone/"
  }

  depends_on = [
    aws_lambda_permission.allow_bucket]
}



