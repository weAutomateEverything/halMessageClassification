resource "aws_iam_role" "halMessageClassification_lambda" {
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
}

resource "aws_iam_role_policy" "halMessageClassification_lambda_policy" {
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "comprehend:*"
      ],
      "Resource": [
        "*"
      ]
    },{
      "Effect":"Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": [
        "${aws_dynamodb_table.HAL_TEXT_AUDIT.arn}"
      ]
    },
    {
         "Effect":"Allow",
         "Action":"logs:CreateLogGroup",
         "Resource":"*"
    },
    {
         "Effect":"Allow",
         "Action":[
            "logs:CreateLogStream",
            "logs:PutLogEvents"
         ],
         "Resource":[
            "*"
         ]
    }
  ]
}
EOF
  role = "${aws_iam_role.halMessageClassification_lambda.name}"
}

resource "aws_lambda_function" "halMessageClassification" {
  function_name = "halMessageClassification"
  handler = "main"
  role = "${aws_iam_role.halMessageClassification_lambda.arn}"
  runtime = "go1.x"
  filename = "../main.zip"
  source_code_hash = "${base64sha256(file("../main.zip"))}",
  publish = true

}