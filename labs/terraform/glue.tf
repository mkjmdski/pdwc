resource "aws_glue_catalog_database" "datalake_db_raw_zone" {
  name = "datalake_raw_${var.account_number}_${var.student_initials}_${var.student_index_no}"
}

resource "aws_glue_catalog_database" "datalake_db_processed_zone" {
  name = "datalake_processed_${var.account_number}_${var.student_initials}_${var.student_index_no}"
}

resource "aws_glue_crawler" "main" {
  database_name = aws_glue_catalog_database.datalake_db_raw_zone.name
  name          = "crawler-${var.student_initials}-${var.student_index_no}"
  role          = var.lab_role_arn
  table_prefix  = "crawler_"

  #   schedule = ""
  schedule = "cron(0/5 * * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.landings["raw"].bucket}/"
  }
}
