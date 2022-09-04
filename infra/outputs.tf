# Output value definitions

output "lambda_invoke_url_base" {
  description = "Url invoking lambda"

  value = format("http://localhost:4566/restapis/%s/poc/_user_request_/hello",aws_api_gateway_rest_api.lambda.id)
}

output "lambda_invoke_url_with_parameter" {
  description = "Url invoking lambda"

  value = format("http://localhost:4566/restapis/%s/poc/_user_request_/hello?name=Fulll",aws_api_gateway_rest_api.lambda.id)
}
