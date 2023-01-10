
data "aws_caller_identity" "current" {}

resource "aws_api_gateway_rest_api" "discord_github_api_gateway" {
  name = "discord_github_api_gateway"
}

resource "aws_api_gateway_resource" "api_resource" {
  parent_id   = aws_api_gateway_rest_api.discord_github_api_gateway.root_resource_id
  path_part   = "api"
  rest_api_id = aws_api_gateway_rest_api.discord_github_api_gateway.id
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.discord_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.myregion}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.discord_github_api_gateway.id}/*/${aws_api_gateway_method.api_post_method.http_method}${aws_api_gateway_resource.api_resource.path}"
}

resource "aws_api_gateway_api_key" "discord_github_api_key" {
  name = "discord_github_api_key"
}


resource "aws_api_gateway_method" "api_post_method" {
  authorization = "NONE"
  http_method   = "POST"
  api_key_required = "true"
  resource_id   = aws_api_gateway_resource.api_resource.id
  rest_api_id   = aws_api_gateway_rest_api.discord_github_api_gateway.id
}

resource "aws_api_gateway_integration" "api_post_integration" {
  http_method = aws_api_gateway_method.api_post_method.http_method
  resource_id = aws_api_gateway_resource.api_resource.id
  rest_api_id = aws_api_gateway_rest_api.discord_github_api_gateway.id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.discord_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "api_gw_deployment" {
  rest_api_id = aws_api_gateway_rest_api.discord_github_api_gateway.id

  triggers = {
    # NOTE: The configuration below will satisfy ordering considerations,
    #       but not pick up all future REST API changes. More advanced patterns
    #       are possible, such as using the filesha1() function against the
    #       Terraform configuration file(s) or removing the .id references to
    #       calculate a hash against whole resources. Be aware that using whole
    #       resources will show a difference after the initial implementation.
    #       It will stabilize to only change when resources change afterwards.
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api_resource.id,
      aws_api_gateway_method.api_post_method.id,
      aws_api_gateway_integration.api_post_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod_stage" {
  deployment_id = aws_api_gateway_deployment.api_gw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.discord_github_api_gateway.id
  stage_name    = "prod"
}
resource "aws_api_gateway_usage_plan" "discord_github_usage_plan" {
  name         = "discord_github_usage_plan"
  description  = "Allow some calls"
  product_code = "MYCODE"


  api_stages {
    api_id = aws_api_gateway_rest_api.discord_github_api_gateway.id
    stage  = aws_api_gateway_stage.prod_stage.stage_name
  }

  quota_settings {
    limit  = 2000
    offset = 2
    period = "WEEK"
  }

  throttle_settings {
    burst_limit = 5
    rate_limit  = 10
  }
}
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.discord_github_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.discord_github_usage_plan.id
}