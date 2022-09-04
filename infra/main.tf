terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
  skip_credentials_validation = true
  skip_requesting_account_id = true
  skip_metadata_api_check = true
  s3_use_path_style = true

  endpoints {
    apigateway = "http://localstack:4566"
    iam = "http://localstack:4566"
    lambda = "http://localstack:4566"
    s3 = "http://localstack:4566"
    cloudwatch = "http://localstack:4566"
  }
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

#  acl = "private"
}


data "archive_file" "lambda_hello_world" {
  type = "zip"

  source_dir  = "${path.module}/hello-world"
  output_path = "${path.module}/hello-world.zip"
}

resource "aws_s3_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}

resource "aws_lambda_function" "hello_world" {
  function_name = "hello"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
#  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_object.lambda_hello_world.key

  runtime = "nodejs14.x"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

#resource "aws_cloudwatch_log_group" "hello_world" {
#  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"
#
#  retention_in_days = 30
#}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }
    ]
  })
}

resource "aws_api_gateway_rest_api" "lambda" {
  name        = "serverless_lambda_gw"
}



resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  parent_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  resource_id = aws_api_gateway_method.proxyMethod.resource_id
  http_method = aws_api_gateway_method.proxyMethod.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_world.invoke_arn
}




resource "aws_api_gateway_method" "proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda.id
  resource_id   = aws_api_gateway_rest_api.lambda.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda.id
  resource_id = aws_api_gateway_method.proxy_root.resource_id
  http_method = aws_api_gateway_method.proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_world.invoke_arn
}


resource "aws_api_gateway_deployment" "apideploy" {
  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda.id
  stage_name  = "poc"
}


#resource "aws_apigatewayv2_api" "lambda" {
#  name          = "serverless_lambda_gw"
#  protocol_type = "HTTP"
#}
#
#resource "aws_apigatewayv2_stage" "lambda" {
#  api_id = aws_apigatewayv2_api.lambda.id
#
#  name        = "serverless_lambda_stage"
#  auto_deploy = true

#  access_log_settings {
#    destination_arn = aws_cloudwatch_log_group.api_gw.arn
#
#    format = jsonencode({
#      requestId               = "$context.requestId"
#      sourceIp                = "$context.identity.sourceIp"
#      requestTime             = "$context.requestTime"
#      protocol                = "$context.protocol"
#      httpMethod              = "$context.httpMethod"
#      resourcePath            = "$context.resourcePath"
#      routeKey                = "$context.routeKey"
#      status                  = "$context.status"
#      responseLength          = "$context.responseLength"
#      integrationErrorMessage = "$context.integrationErrorMessage"
#    }
#    )
#  }
#}

#resource "aws_apigatewayv2_integration" "hello_world" {
#  api_id = aws_apigatewayv2_api.lambda.id
#
#  integration_uri    = aws_lambda_function.hello_world.invoke_arn
#  integration_type   = "AWS_PROXY"
#  integration_method = "POST"
#}
#
#resource "aws_apigatewayv2_route" "hello_world" {
#  api_id = aws_apigatewayv2_api.lambda.id
#
#  route_key = "GET /hello"
#  target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
#}

#resource "aws_cloudwatch_log_group" "api_gw" {
#  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
#
#  retention_in_days = 30
#}

#resource "aws_lambda_permission" "api_gw" {
#  statement_id  = "AllowExecutionFromAPIGateway"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.hello_world.function_name
#  principal     = "apigateway.amazonaws.com"
#
#  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
#}
