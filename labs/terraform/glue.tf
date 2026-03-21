resource "aws_glue_catalog_database" "datalake_db_raw_zone" {
    name = "datalake_raw_${var.account_number}_${var.student_initials}_${var.student_index_no}"
}
