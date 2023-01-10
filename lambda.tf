resource "aws_iam_role" "discord_lambda_role" {
  name = "discord_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
managed_policy_arns = [
  data.aws_iam_policy.AWSLambdaExecute.arn
]
}

data "aws_iam_policy" "AWSLambdaExecute" {
  arn = "arn:aws:iam::aws:policy/AWSLambdaExecute"
}


resource "aws_lambda_function" "discord_lambda_function" {
  function_name = "discord_github_webhook_manager"
  description   = "Handles discord webhooks and posts to the right area in discord."
  filename      = data.archive_file.lambda.output_path
  runtime       = "python3.8"
  handler       = "main.lambda_handler"
  timeout       = 30
  memory_size   = 128
  source_code_hash = data.archive_file.lambda.output_base64sha256

  role = aws_iam_role.discord_lambda_role.arn

}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/python/main.py"
  output_path = "${path.module}/python/main.py.zip"
}