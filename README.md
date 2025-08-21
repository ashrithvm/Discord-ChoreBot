# Discord Chore Bot

A serverless, automated Discord bot that assigns weekly chores to users on a rotating schedule. Built with a 100% serverless architecture on AWS and managed with Terraform.

## Overview

This project solves the simple but common problem of fairly delegating recurring tasks within a group. The Discord Chore Bot automatically posts a message every Saturday morning to a designated channel, assigning chores like "Bathroom," "Kitchen," and "Floor" to a predefined list of users. The assignments rotate each week, ensuring everyone takes a turn with each task.

The entire infrastructure is defined as code using **Terraform**, making it easy to deploy, manage, and modify. It runs entirely on the **AWS Free Tier**, making it a cost-effective solution.

## Features

-   **Automated Weekly Posts**: Automatically sends a message every Saturday morning.
    
-   **Rotating Schedule**: Cycles through the list of users and chores each week.
    
-   **Serverless**: No servers to manage. The bot runs on-demand using AWS Lambda.
    
-   **Persistent State**: Uses DynamoDB to remember the current assignment state, even between executions.
    
-   **Infrastructure as Code (IaC)**: The entire AWS infrastructure is managed by Terraform for easy and repeatable deployments.
    
-   **Customizable**: Easily change the list of users, chores, and the schedule by modifying the Terraform configuration.
    

## Tech Stack & Architecture

This project is built with the following technologies:

-   **Discord API**: For sending messages to a server channel.
    
-   **AWS Lambda**: Runs the bot's Python code in a serverless environment.
    
-   **Amazon DynamoDB**: A NoSQL database to store the current chore rotation state.
    
-   **Amazon EventBridge**: A serverless scheduler that triggers the Lambda function weekly.
    
-   **AWS IAM**: Manages permissions for the Lambda function to access other AWS services.
    
-   **Terraform**: Defines and provisions all the necessary AWS resources.
    

### Architecture Diagram

```
┌───────────────────┐       ┌───────────────────┐       ┌───────────────────┐
│ Amazon EventBridge│       │    AWS Lambda     │       │  Amazon DynamoDB  │
│ (Weekly Schedule) │──────►│  (Python Bot)     │──────►│ (Stores State)    │
└───────────────────┘       └─────────┬─────────┘       └───────────────────┘
                                      │
                                      ▼
                             ┌───────────────────┐
                             │   Discord API     │
                             │ (Sends Message)   │
                             └───────────────────┘

```

## Prerequisites

Before you begin, ensure you have the following installed and configured:

-   **Terraform**: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli "null")
    
-   **AWS CLI**: [Install and Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html "null") with your credentials.
    
-   **Python 3.8+** and **pip**.
    
-   A **Discord Account** with a server where you have administrative privileges.
    

## Setup and Deployment

Follow these steps to deploy the bot to your own AWS account.

### 1. Create a Discord Bot

First, you need to create the bot application in Discord to get your credentials.

1.  Go to the [Discord Developer Portal](https://www.google.com/search?q=https://discord.com/developers/applications "null") and create a **New Application**.
    
2.  Navigate to the **Bot** tab and click **Add Bot**.
    
3.  **Copy the Bot Token**: Under the bot's username, click **Reset Token** and copy the token. You will need this for `var.discord_bot_token`.
    
4.  **Invite the Bot**: Go to **OAuth2 -> URL Generator**. Select the `bot` scope. Under "Bot Permissions," select `Send Messages`. Copy the generated URL and paste it into your browser to invite the bot to your server.
    
5.  **Get Channel ID**: In your Discord server, enable **Developer Mode** (User Settings > Advanced). Right-click on the channel where you want the bot to post and select **Copy Channel ID**. You will need this for `var.discord_channel_id`.
    

### 2. Clone the Repository

```
git clone <your-repository-url>
cd discord-chore-bot

```

### 3. Install Python Dependencies

The bot's code requires the `requests` library. We need to install it in the `src` directory so Terraform can package it with the Lambda function.

```
pip install -r src/requirements.txt -t src/

```

### 4. Deploy with Terraform

1.  **Initialize Terraform**:
    
    ```
    terraform init
    
    ```
    
2.  **Plan the Deployment**: Run the plan command. Terraform will prompt you to enter your secret variables.
    
    ```
    terraform plan
    
    ```
    
    -   Enter your **Discord Bot Token** when prompted for `var.discord_bot_token`.
        
    -   Enter your **Discord Channel ID** when prompted for `var.discord_channel_id`.
        
3.  **Apply the Configuration**: If the plan looks correct, apply it to create the AWS resources.
    
    ```
    terraform apply
    
    ```
    
    Confirm the prompt by typing `yes`. Terraform will now build and deploy all the necessary infrastructure.
    

## Usage

Once deployed, the bot will automatically send a message to your specified Discord channel **every Saturday at 2:00 PM UTC**. The message will list the chore assignments for the week. The following week, the assignments will rotate. No further action is needed!

To change the users, chores, or schedule, simply modify the `aws_dynamodb_table_item` resource or the `aws_cloudwatch_event_rule` cron expression in `main.tf` and run `terraform apply` again.

### Cleaning Up

To remove all the AWS resources created by this project, run the following command:

```
terraform destroy

```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any bugs or feature requests.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.