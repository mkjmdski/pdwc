resource "aws_s3_bucket" "athena_results" {
  bucket        = "athena-results-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results_lifecycle" {
  bucket = aws_s3_bucket.athena_results.id
  rule {
    id     = "standard-expiration"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}
resource "aws_athena_workgroup" "athena_workgroup" {
  name = "development"
  configuration {
    enforce_workgroup_configuration = true
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/output/"
    }
  }
  force_destroy = true
}
