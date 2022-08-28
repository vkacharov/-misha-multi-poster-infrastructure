variable "ApplicationId" {
  type = string
}

resource "aws_ssm_parameter" "multi_poster_website_application_id" {
  name  = "MishaMultiPosterApplicationId"
  type  = "String"
  value = var.ApplicationId
}

resource "aws_iam_role" "multi_poster_website_code_build_role" {
  name = "multi_poster_website_code_build_role"

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

resource "aws_iam_role_policy" "multi_poster_website_code_build_role_policy" {
  role = aws_iam_role.multi_poster_website_code_build_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
        "Effect": "Allow",
        "Resource": [
            "${aws_s3_bucket.multi_poster_website_bucket.arn}",
            "${aws_s3_bucket.multi_poster_website_bucket.arn}/*"
        ],
        "Action": [
            "s3:PutObject",
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ssm:GetParameter",
            "ssm:GetParameters"
        ],
        "Resource": [
            "${aws_ssm_parameter.multi_poster_website_application_id.arn}"
        ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "multi_poster_website_code_build" {
  name          = "multi-poster-website-code-build"
  description   = "Misha Multi Poster website code build"
  build_timeout = "5"
  service_role  = "${aws_iam_role.multi_poster_website_code_build_role.arn}"

  artifacts {
    type                = "S3"
    location            = "${aws_s3_bucket.multi_poster_website_bucket.arn}"
    name                = "/"
    packaging           = "NONE"
    encryption_disabled = true
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

      environment_variable {
        name  = "VITE_APPID"
        value = "${aws_ssm_parameter.multi_poster_website_application_id.name}"
        type  = "PARAMETER_STORE"
    }
  }
  
  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/multi-poster-website-code-build"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/vkacharov/misha-multi-poster-website"
    git_clone_depth = 1
    buildspec       = file("${path.module}/buildspec.yaml")
  }

  source_version = "main"
}

resource "aws_codebuild_webhook" "multi_poster_website_code_build_webhook" {
  project_name = aws_codebuild_project.multi_poster_website_code_build.name
  build_type   = "BUILD"
}