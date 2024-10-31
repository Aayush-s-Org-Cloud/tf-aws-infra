resource "aws_iam_policy" "s3_full_access_policy" {
  name        = "S3_FullAccess_Policy"
  description = "Policy for full S3 access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket",
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl"
        ],
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      }
    ]
  })
}

# Define a policy for Route 53 management
resource "aws_iam_policy" "route53_access_policy" {
  name        = "Route53_FullAccess_Policy"
  description = "Policy for managing Route 53 records"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:UpdateHostedZoneComment",
          "route53:GetChange",
          "route53:GetCheckerIpRanges",
          "route53:ListHostedZonesByName",
          "route53:ListTagsForResource",
          "route53:ChangeTagsForResource",
          "route53:ListHealthChecks",
          "route53:GetHealthCheck",
          "route53:GetHostedZoneLimit",
          "route53:ListQueryLoggingConfigs",
          "route53domains:CheckDomainAvailability",
          "route53domains:RegisterDomain",
          "route53domains:DeleteDomain",
          "route53domains:GetDomainDetail",
          "route53domains:ListDomains",
          "route53domains:ListTagsForDomain",
          "route53domains:UpdateDomainContact",
          "route53domains:ViewBilling"

        ],
        Resource = "*"
      }
    ]
  })
}

# Define a policy for CloudWatch logging and metrics
resource "aws_iam_policy" "cloudwatch_logging_policy" {
  name        = "CloudWatch_Logging_Policy"
  description = "Policy for CloudWatch logging and metrics"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "ssm:GetParameter",
          "logs:DescribeLogGroups"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create the IAM role to be assumed by the EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "EC2RoleForRoute53_S3_CloudWatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# Attach individual policies to the IAM role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_full_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "route53_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.route53_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_logging_policy.arn
}

# Create an instance profile to link the role to the EC2 instance
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2InstanceProfileForRoute53_S3_CloudWatch"
  role = aws_iam_role.ec2_role.name
}