variable aws_region {
  default = "eu-west-1"
}

variable goTestArn {
  default = "arn:aws:lambda:eu-west-1:801774479614:function:apex-test_goTest"
} 

variable goTestName {
  default = "apex-test_goTest"
} 

provider "aws" {
  profile     = "jcd-ppr"
}

# API Gateway
resource "aws_api_gateway_rest_api" "TestAPI" {
  name        = "Test API"
  description = "Plugging goTest function to internet"
}

# Resource path
resource "aws_api_gateway_resource" "TestAPIResource" {
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  parent_id = "${aws_api_gateway_rest_api.TestAPI.root_resource_id}"
  path_part = "test"
}

resource "aws_api_gateway_method" "GetMethod" {
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  resource_id = "${aws_api_gateway_resource.TestAPIResource.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  resource_id = "${aws_api_gateway_resource.TestAPIResource.id}"
  http_method = "${aws_api_gateway_method.GetMethod.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration" "TestAPI-integration" {
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  resource_id = "${aws_api_gateway_resource.TestAPIResource.id}"
  http_method = "${aws_api_gateway_method.GetMethod.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.goTestArn}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_integration_response" "TestAPI-integrationresponse" {
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  resource_id = "${aws_api_gateway_resource.TestAPIResource.id}"
  http_method = "${aws_api_gateway_method.GetMethod.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
}

resource "aws_api_gateway_deployment" "example_deployment_ppr" {
  depends_on = [
    "aws_api_gateway_method.GetMethod",
    "aws_api_gateway_integration.TestAPI-integration"
  ]
  rest_api_id = "${aws_api_gateway_rest_api.TestAPI.id}"
  stage_name = "api"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.goTestName}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.aws_region}:801774479614:${aws_api_gateway_rest_api.TestAPI.id}/*/${aws_api_gateway_method.GetMethod.http_method}${aws_api_gateway_resource.TestAPIResource.path}"
}


output "ppr_url" {
  value = "https://${aws_api_gateway_deployment.example_deployment_ppr.rest_api_id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.example_deployment_ppr.stage_name}"
}
