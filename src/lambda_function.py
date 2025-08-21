import json
import os
import boto3
import requests

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DYNAMODB_TABLE_NAME'])

# Get secrets from environment variables
BOT_TOKEN = os.environ['DISCORD_BOT_TOKEN']
CHANNEL_ID = os.environ['DISCORD_CHANNEL_ID']

def lambda_handler(event, context):
    try:
        # 1. Get the current state from DynamoDB
        response = table.get_item(Key={'AssignmentId': 'latest'})
        item = response['Item']

        people = [p for p in item['people']]
        chores = [c for c in item['chores']]
        current_turn = int(item['current_turn'])

        # 2. Create the message for this week
        message_lines = []
        num_people = len(people)

        for i, chore in enumerate(chores):
            person_index = (current_turn + i) % num_people
            person = people[person_index]
            message_lines.append(f"{person} is assigned {chore}")

        message = "\n".join(message_lines)

        # 3. Send the message to Discord
        discord_url = f"https://discord.com/api/v10/channels/{CHANNEL_ID}/messages"
        headers = {
            "Authorization": f"Bot {BOT_TOKEN}",
            "Content-Type": "application/json"
        }
        data = {"content": f"**This week's chores:**\n{message}"}

        r = requests.post(discord_url, headers=headers, json=data)
        r.raise_for_status() # Raises an exception for bad status codes

        # 4. Update the turn for next week
        next_turn = (current_turn + 1) % num_people
        table.update_item(
            Key={'AssignmentId': 'latest'},
            UpdateExpression='SET current_turn = :val',
            ExpressionAttributeValues={':val': next_turn}
        )

        return {
            'statusCode': 200,
            'body': json.dumps('Chore message sent successfully!')
        }

    except Exception as e:
        print(f"Error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'An error occurred: {str(e)}')
        }

