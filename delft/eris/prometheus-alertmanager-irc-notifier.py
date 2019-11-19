

import json, os
from http import HTTPStatus
from flask import Flask, request
import pika

app = Flask(__name__)
parameters = pika.URLParameters(os.environ["AMQP_ENDPOINT"])

externalUrl = os.environ["EXTERNAL_URL"]

def send_notice(target, body):
    # alerts need to be reliable, so this is slow,
    # but has no problems with heartbeat timeouts
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    body = json.dumps({
        'message_type': 'notice',
        'target': target,
        'body': body
    })
    channel.basic_publish(exchange='',
                      routing_key='queue-publish',
                      body=body)

@app.route("/", methods=['POST'])
def webhook():
    target_id = request.args["target_id"]
    send_notice(target_id, format_event(request.json))
    return ('', HTTPStatus.NO_CONTENT)

def format_event(event):
    message = event.get("status", "unknown") + ": "

    commonLabels = event.get("commonLabels", {})
    alertname = commonLabels.get("alertname", "various alerts")

    message += alertname + ": "
    message += externalUrl

    return message

