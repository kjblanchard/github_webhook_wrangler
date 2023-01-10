from urllib import request
import logging

import json

def lambda_handler(event, context):
    if logging.getLogger().hasHandlers:
        logging.getLogger().setLevel(logging.INFO)
    else:
        logging.basicConfig(level=logging.INFO)
    logging.info(event)
    logging.info(context)
    jsonString = json.dumps(event, indent=4)
    logging.info(jsonString)
    return {
        'statusCode': 200,
        'body': json.dumps({
            "Hellos": "World"
        })
    }