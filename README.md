# terraform-rdgateway-aws
This repository contains Terraform configurations that deploy an [Remote Desktop Gateway](https://docs.aws.amazon.com/quickstart/latest/rd-gateway/overview.html) solution in an AWS account.

While AWS have published a Quick Start that uses CloudFormation to deploy the RD Gateway in various scenarios, they do not provide a solution for the [SSL certificates](https://docs.aws.amazon.com/quickstart/latest/rd-gateway/architecture.html) that are rewuired for each RD Gateway instance.

The solution presented here uses [certbot](https://certbot.eff.org/about/) running as a [Lambda](https://aws.amazon.com/lambda/) function that gets a [Letsencrypt](https://letsencrypt.org/) SSL certificate that is good for 90 days. The certbot Lambda function runs on a schedule and gets a new SSL certificate every 60 days and saves the certificate in an S3 bucket. Upon receiving a new SSL certificate, the S3 bucket notifies an SQS queue so that the RD Gateway that listenes to that SQS queue every day is able to download the new certificate from S3 and install it on the RD Gateway server. This workflow ensures that the RD Gateway instance has a valid SSL certificate that is renenwed forever.

## Quick start

## Credits