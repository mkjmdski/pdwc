variable "account_number" {
  description = "Account number"
  type = number
}

variable "region" {
  description = "Region name - must be NVirginia us-east-1"
  type = string
  default = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type = string
  default = "dev"
}

variable "student_initials" {
  description = "letters of first and last names"
  type = string
}

variable "student_full_name" {
  description = "Student's full name"
  type = string
}

variable "student_index_no" {
  description = "Index no"
  type = string
}

variable "lab_role_arn" {
  description = "the role we use for all labs, dont use a single role for everything! it is an anti-pattern!!!!"
  type = string

}
