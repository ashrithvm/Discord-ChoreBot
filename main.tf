# main.tf

# Configure the AWS provider
provider "aws" {
  region = "us-east-2" # Or your preferred region
}

# --- IAM ROLE FOR LAMBDA ---
# This is the equivalent of Step 3 in the manual.

# The execution role for the Lambda function
resource "aws_iam_role" "lambda_exec_role" {
  name = "DiscordChoreBotRole"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# The policy that grants access to DynamoDB
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "DynamoDBChoreBotPolicy"
  description = "Allows Lambda to read/write to the ChoreAssignments table"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.chore_assignments.arn
      }
    ]
  })
}

# Attach the basic Lambda execution policy (for logs)
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach our custom DynamoDB policy
resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}


# --- DYNAMODB TABLE ---
# This is the equivalent of Step 2 in the manual.

resource "aws_dynamodb_table" "chore_assignments" {
  name         = "ChoreAssignments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "AssignmentId"

  attribute {
    name = "AssignmentId"
    type = "S"
  }
}

# Add the initial item to the DynamoDB table
resource "aws_dynamodb_table_item" "initial_assignment" {
  table_name = aws_dynamodb_table.chore_assignments.name
  hash_key   = aws_dynamodb_table.chore_assignments.hash_key

  item = jsonencode({
    AssignmentId = { S = "latest" },
    chores       = { L = [{ S = "Bathroom" }, { S = "Kitchen" }, { S = "Floor" }] },
    people       = { L = [{ S = "Ash" }, { S = "Ethan" }, { S = "Joshua" }] },
    current_turn = { N = "0" }
  })
}

# --- LAMBDA FUNCTION ---
# This is the equivalent of Step 4 in the manual.

# First, we need to package our Python code and its dependencies into a zip file.
# Before running terraform, run this command in your terminal:
# pip install -r src/requirements.txt -t src/
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_package.zip"
}

resource "aws_lambda_function" "chore_bot_lambda" {
  function_name = "discord-chore-bot"
  role          = aws_iam_role.lambda_exec_role.arn
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DISCORD_BOT_TOKEN   = var.discord_bot_token
      DISCORD_CHANNEL_ID  = var.discord_channel_id
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.chore_assignments.name
    }
  }

  # Wait for the IAM role policies to be attached before creating the function
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.dynamodb_access
  ]
}

# --- EVENTBRIDGE SCHEDULE ---
# This is the equivalent of Step 5 in the manual.

resource "aws_cloudwatch_event_rule" "saturday_schedule" {
  name                = "RunDiscordChoreBotWeekly"
  description         = "Triggers the chore bot every Saturday"
  schedule_expression = "cron(0 14 ? * SAT *)" # 2 PM UTC on Saturdays
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.saturday_schedule.name
  arn  = aws_lambda_function.chore_bot_lambda.arn
}

# Grant EventBridge permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.chore_bot_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.saturday_schedule.arn
}