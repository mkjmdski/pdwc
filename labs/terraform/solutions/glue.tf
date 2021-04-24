resource "aws_glue_catalog_database" "datalake_db_raw_zone" {
  name = "datalake_${var.environment}_${var.account_number}_${var.student_initials}_${var.student_index_no}"
}


resource "aws_glue_crawler" "glue_crawler_raw_zone" {
  database_name = aws_glue_catalog_database.datalake_db_raw_zone.name
  name = "gc-raw-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  role = aws_iam_role.glue_crawler_role.arn
  table_prefix = "crawler_"

  s3_target {
    path = "s3://${aws_s3_bucket.main_dl_bucket.bucket}/raw-zone/stockdata/"
  }

  tags = merge(local.common_tags, )
}