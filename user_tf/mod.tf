terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      configuration_aliases = [ aws.nextjs-aws-lambda ]
    }
  }
}


locals {
  project_name = "nextjs"
}

data aws_caller_identity current {
  provider = aws.nextjs-aws-lambda
}

data aws_apigatewayv2_apis www {
  provider      = aws.nextjs-aws-lambda
  name          = "asml-${local.project_name}-www"
  protocol_type = "HTTP"
}

data aws_apigatewayv2_api www {
  provider = aws.nextjs-aws-lambda
  api_id   = tolist(data.aws_apigatewayv2_apis.www.ids)[0]
}

module server_policy {
  source = "./function-policy"
  providers = {
    aws = aws.nextjs-aws-lambda
  }

  project_name = local.project_name
  service  = "www"
  function = "server"
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["execute-api:Invoke"],
      "Resource": "arn:aws:execute-api:us-east-1:${data.aws_caller_identity.current.account_id}:${data.aws_apigatewayv2_api.www.api_id}/*/POST/api/counter/*"
    }
  ]
}
EOF
}

module counter_policy {
  source = "./function-policy"
  providers = {
    aws = aws.nextjs-aws-lambda
  }

  project_name = local.project_name
  service  = "www"
  function = "counter"
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:235724345984:secret:demos/nextjs/xata-osxcK4"
    },
    {
      "Effect": "Allow",
      "Action": "secretsmanager:ListSecrets",
      "Resource": "*"
    }
  ]
}
EOF
}
