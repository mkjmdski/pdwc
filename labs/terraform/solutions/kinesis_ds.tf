resource "aws_kinesis_stream" "cryptostock_stream" {
  name = "cryptostock-${var.environment}-${var.account_number}-${var.student_initials}-${var.student_index_no}"
  shard_count = 1
  enforce_consumer_deletion = true

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords"
  ]

  tags = merge(local.common_tags, )
}