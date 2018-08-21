resource "aws_codedeploy_app" "halMessageClassification" {
  name = "halMessageClassification"
  compute_platform = "Lambda"
}

resource "aws_iam_role" "halMessageClassification_deploy" {
  name = "halMessageClassification_deplot"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_deployment_group" "halMessageClassification" {
  app_name = "${aws_codedeploy_app.halMessageClassification.name}"
  deployment_group_name = "halMessageClassification"
  service_role_arn = "${aws_iam_role.halMessageClassification_deploy.arn}"
  deployment_config_name = "CodeDeployDefault.LambdaAllAtOnce"

  deployment_style {
    deployment_type = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

}