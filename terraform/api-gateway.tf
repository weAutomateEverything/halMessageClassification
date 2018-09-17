resource "aws_api_gateway_rest_api" "hal" {
  name        = "hal"
  description = "Hal API Gateway"
}

resource "aws_api_gateway_resource" "halMessageClassification" {
  rest_api_id = "${aws_api_gateway_rest_api.hal.id}"
  parent_id   = "${aws_api_gateway_rest_api.hal.root_resource_id}"
  path_part   = "halMessageClassification"
}

resource "aws_api_gateway_method" "halMessageClassification" {
  rest_api_id   = "${aws_api_gateway_rest_api.hal.id}"
  resource_id   = "${aws_api_gateway_resource.halMessageClassification.id}"
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.hal.id}"
  resource_id = "${aws_api_gateway_method.halMessageClassification.resource_id}"
  http_method = "${aws_api_gateway_method.halMessageClassification.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:eu-west-1:lambda:path/2015-03-31/functions/${aws_lambda_function.halMessageClassification.arn}/invocations"
}

resource "aws_api_gateway_deployment" "hal" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
  ]

  rest_api_id = "${aws_api_gateway_rest_api.hal.id}"
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.halMessageClassification.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "arn:aws:execute-api:eu-west-1:954064918141:${aws_api_gateway_rest_api.hal.id}/*/${aws_api_gateway_method.halMessageClassification.http_method}${aws_api_gateway_resource.halMessageClassification.path}"
}

output "base_url" {
  value = "${aws_api_gateway_deployment.hal.invoke_url}"
}