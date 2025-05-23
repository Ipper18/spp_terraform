output "function_name" {
  description = "Nazwa funkcji Lambda"
  value       = aws_lambda_function.temperature_sensor_handler.function_name
}
output "function_arn" {
  description = "ARN funkcji Lambda"
  value       = aws_lambda_function.temperature_sensor_handler.arn
}
output "event_mapping_id" {
  description = "ID mapowania zdarzeń SQS->Lambda"
  value       = aws_lambda_event_source_mapping.sqs_to_lambda.uuid
}
