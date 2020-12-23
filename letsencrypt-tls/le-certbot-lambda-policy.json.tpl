{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudWatchLogsAccess",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "Route53GlobalAccess",
      "Action": [
        "route53:GetChange",
        "route53:ListHostedZones"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchAccess",
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "S3BucketAccess",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${s3_bucket_arn}/*"
    },
    {
      "Sid": "S3GlobalAccess",
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${s3_bucket_arn}"
    },
    {
      "Sid": "Route53ZoneAccess",
      "Action": [
        "route53:ChangeResourceRecordSets",
        "route53:GetHostedZone",
        "route53:ListResourceRecordSets"
      ],
      "Effect": "Allow",
      "Resource": "${route53_zone_arn}"
    }
  ]
}