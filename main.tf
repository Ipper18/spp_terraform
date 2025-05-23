terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "terraform-zad-spp"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-zad-spp-db"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_iam_role" "lab_role" {
  name = var.role_name
}

data "aws_sqs_queue" "sensor_queue" {
  name = var.sqs_queue_name
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "$C:\Users\Igor\Desktop\Terraform\TemperatureSensorHandler-e0dc91ce-48a6-48a5-93b8-a243bfc29584"
  output_path = "$C:\Users\Igor\Desktop\Terraform\TemperatureSensorHandler-e0dc91ce-48a6-48a5-93b8-a243bfc29584/lambda.zip"
}

resource "aws_lambda_function" "temperature_sensor_handler" {
  function_name = "TemperatureSensorHandler"
  role          = data.aws_iam_role.lab_role.arn
  runtime       = "python3.9"
  handler       = "main.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      SNS_TOPIC_ARN      = var.sns_topic_arn
      DYNAMO_TABLE_NAME  = var.dynamodb_table_name
      SQS_QUEUE_URL      = data.aws_sqs_queue.sensor_queue.id
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = data.aws_sqs_queue.sensor_queue.arn
  function_name    = aws_lambda_function.temperature_sensor_handler.arn
  enabled          = true
  batch_size       = 10
}
