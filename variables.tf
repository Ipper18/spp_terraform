variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "role_name" {
  type    = string
  default = "LabRole"
}
variable "sqs_queue_name" {
  type    = string
  default = "SensorDataQueue"
}
variable "sns_topic_arn" {
  type    = string
  default = "arn:aws:sns:us-east-1:707888537904:CriticalTempNotification:2f414424-dca7-448b-84e9-8acff64e1673"
}
variable "dynamodb_table_name" {
  type    = string
  default = "BrokenSensors"
}
