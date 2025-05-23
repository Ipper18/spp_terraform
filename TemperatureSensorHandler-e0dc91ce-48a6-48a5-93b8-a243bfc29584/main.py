import json
import math
import os
import boto3

# DynamoDB - Tabela do oznaczania sensora jako uszkodzonego
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("BrokenSensors")

# SNS do wysyłania powiadomień w przypadku temperatur krytycznych
sns_client = boto3.client("sns")
SNS_Topic_Arn = "arn:aws:sns:us-east-1:707888537904:CriticalTempNotification"

# SQS - klient do wysyłania komunikatów
sqs_client = boto3.client("sqs")
QUEUE_URL = os.environ.get("QUEUE_URL", "")

def mark_sensor_broken(sensor_id):
    table.put_item(
        Item={
            "sensor_id": sensor_id,
            "broken": True
        }
    )

def lambda_handler(event, context):

    sensor_id = event.get("sensor_id")
    location_id = event.get("location_id") 
    R = event.get("value")
    timestamp = event.get("timestamp")

    # Sprawdzenie podstawowych danych
    if not sensor_id or R is None:
        mark_sensor_broken(sensor_id or "UNKNOWN")
        return {
            "error": "Missing Error Data"
        }

    # Sprawdzenie zakresu R
    if R < 1 or R > 20000:
        mark_sensor_broken(sensor_id)
        return {
            "error": "Value is out of range"
        }
    
    # Obliczanie temperatury
    a = 1.40e-3
    b = 2.37e-4
    c = 9.90e-8
    try:
        lnR = math.log(R)
        T_K = 1.0 / (a + b * lnR + c * (lnR ** 3))
        T_C = T_K - 273.15
    except Exception as e:
        mark_sensor_broken(sensor_id)
        return {
            "error": "Error in calculation"
        }
    
    message_body = {
        "sensor_id": sensor_id,
        "location_id": location_id,
        "temperature": T_C,
        "timestamp": timestamp
    }

    if QUEUE_URL:
        sqs_client.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps(message_body)
        )


    if T_C < 20:
        return {
            "status": "TEMPERATURE IS TOO LOW"
        }
    elif T_C < 100:
        return {
            "status": "TEMPERATURE IS OK"
        }
    elif T_C < 250:
        return {
            "status": "TEMPERATURE IS TOO HIGH"
        }
    else:

        sns_client.publish(
            TopicArn=SNS_Topic_Arn,
            Subject=f"Critical Temperature Alert: {sensor_id}",
            Message=f"Temperature is too high: {T_C}"
        )
        mark_sensor_broken(sensor_id)
        return {
            "status": "TEMPERATURE IS CRITICAL"
        }
