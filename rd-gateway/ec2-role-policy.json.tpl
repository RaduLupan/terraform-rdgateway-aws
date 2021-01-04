{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "SSMAccess",
        "Action": [
          "ssm:Get*",
          "ssm:Describe*",
          "ssm:List*",
          "ssm:CreateAssociation",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssm:UpdateInstanceAssociationStatus"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "S3Access",
        "Action": [
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "SQSAccess",
        "Action": [
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "SNSAccess",
        "Action": [
          "sns:List*",
          "sns:Get*",
          "sns:Publish"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "EC2MessagesAccess",
        "Action": [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "EC2Access",
        "Action": [
          "ec2:DescribeInstanceStatus"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "DSAccess",
        "Action": [
          "ds:CreateComputer",
          "ds:DescribeDirectorie"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "CWLogsAccess",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Effect": "Allow",
        "Resource": "*"
      },
      {
        "Sid": "SSMMessagesAccess",
        "Action": [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }