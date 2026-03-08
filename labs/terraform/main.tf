locals {
  common_tags = {
    purpose     = "UAM Cloud Data Processing"
    environment = "DEV"
    owner       = var.student_full_name
  }
  identifier = "${var.account_number}-${var.student_initials}-${var.student_index_no}"
}