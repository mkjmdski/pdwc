locals {
  zones = {
    raw = {
      db_name      = "datalake_raw_${var.account_number}_${var.student_initials}_${var.student_index_no}"
      crawler_name = "crawler-${var.student_initials}-${var.student_index_no}"
      prefix       = "crawler_"
    }
    processed = {
      db_name      = "datalake_processed_${var.account_number}_${var.student_initials}_${var.student_index_no}"
      crawler_name = "crawler-processed-${var.student_initials}-${var.student_index_no}"
      prefix       = "stockdata_"
    }
  }
}

resource "aws_glue_catalog_database" "zone" {
  for_each = local.zones
  name     = each.value.db_name
}

resource "aws_glue_crawler" "zone" {
  for_each      = local.zones
  database_name = aws_glue_catalog_database.zone[each.key].name
  name          = each.value.crawler_name
  role          = var.lab_role_arn
  table_prefix  = each.value.prefix

  schedule = "cron(0/5 * * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.landings[each.key].bucket}/"
  }
}
