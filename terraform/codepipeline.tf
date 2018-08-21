
resource "aws_s3_bucket" "halMessageClassification_pipeline" {
  bucket = "halmessageclassification-pipeline"
}

resource "aws_iam_role" "halMessageClassification_pipeline" {
  name = "halmessageclassification_pipeline"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "halMessageClassification_pipeline_policy" {
  name = "halMessageClassification_pipeline_policy"
  role = "${aws_iam_role.halMessageClassification_pipeline.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.halMessageClassification_pipeline.arn}",
        "${aws_s3_bucket.halMessageClassification_pipeline.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_codepipeline" "halMessageClassification" {
  "artifact_store" {
    location = "${aws_s3_bucket.halMessageClassification_pipeline.bucket}"
    type = "S3"
  }
  name = "halMessageClassification"
  role_arn = "${aws_iam_role.halMessageClassification_pipeline.arn}"
  "stage" {
    "action" {
      category = "Source"
      name = "Source"
      owner = "ThirdParty"
      provider = "GitHub"
      version = "1"
      configuration {
        Owner = "weAutomateEverything"
        Repo = "halMessageClassification"
        Branch = "master"
        OAuthToken = "${var.github_key}"
      }
      output_artifacts = ["source"]
    }
    name = "SourceCode"
  }
  stage {
    "action" {
      category = "Build"
      name = "Buid"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["source"]
      configuration {
        ProjectName = "${aws_codebuild_project.halMessageClassification.name}"
      }
      output_artifacts = ["build"]
    }
    name = "Build"
  }
  stage {
    "action" {
      category = "Deploy"
      name = "Deploy"
      owner = "AWS"
      provider = "CodeDeploy"
      version = "1"
      configuration {
        ApplicationName = "${aws_codedeploy_app.halMessageClassification.name}"
        DeploymentGroupName = "${aws_codedeploy_deployment_group.halMessageClassification.deployment_group_name}"
      }
    }
    name = "Deploy"
  }
}