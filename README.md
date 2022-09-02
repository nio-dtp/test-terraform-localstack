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

After plan is applied, terminal prints output like
```bash
Outputs:

base_url = "https://qt07xsuurh.execute-api.eu-west-1.amazonaws.com/test"
function_name = "HelloWorld"
lambda_bucket_name = "test-bucket"
```

## Test lambda with apigateway

For now, it's necessary to build request uri by hand

With id given by terraform output, compose curl request
```bash
curl http://localhost:4566/restapis/qt07xsuurh/test/_user_request_/HelloWorld\?Name\=Fulll
```


