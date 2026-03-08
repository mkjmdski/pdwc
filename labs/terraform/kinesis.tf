resource "aws_kinesis_stream" "main" {
  name                      = "cryptostock-${local.identifier}"
  shard_count               = 1
  retention_period          = 24
  enforce_consumer_deletion = true
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
    "IncomingRecords",
    "OutgoingRecords",
  ]
  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}