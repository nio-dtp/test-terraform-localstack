# POC

Is it possible to test locally aws lambda ?

## Tested solution
- emulate aws services with localstack
- deploy aws infrastructure with terraform
- based on terraform lambda [tutorial](https://learn.hashicorp.com/tutorials/terraform/lambda-api-gateway)

## Boot
```bash
docker-compose up
```

Will create aws infrastructure with terraform
- s3
- lambda
- apigateway
- iam

After plan is applied, terminal prints urls
```bash
Outputs:

lambda_invoke_url_base = "http://localhost:4566/restapis/v27lasxpbr/poc/_user_request_/hello"
lambda_invoke_url_with_parameter = "http://localhost:4566/restapis/v27lasxpbr/poc/_user_request_/hello?name=Fulll"

```

## Test lambda with apigateway

Copy/paste one of this url in your browser


