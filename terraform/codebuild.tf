resource "aws_iam_role" "halMessageClassification_codebuild" {
  name = "halmessageclassification_codebuild"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "halMessageClassification_codebuild_policy" {
  role        = "${aws_iam_role.halMessageClassification_codebuild.name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.halMessageClassification_pipeline.arn}",
        "${aws_s3_bucket.halMessageClassification_pipeline.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "halMessageClassification" {
  service_role = "${aws_iam_role.halMessageClassification_codebuild.arn}"
  "artifacts" {
    type = "CODEPIPELINE"
  }
  "environment" {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/golang:1.10"
    type = "LINUX_CONTAINER"
  }
  name = "halMessageClassification"
  "source" {
    type = "CODEPIPELINE"
  }
}