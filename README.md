# terraform-rdgateway-aws
This repository contains Terraform configurations that deploy an [Remote Desktop Gateway](https://docs.aws.amazon.com/quickstart/latest/rd-gateway/overview.html) solution in an AWS account.

While AWS have published a Quick Start that uses CloudFormation to deploy the RD Gateway in various scenarios, they do not provide a solution for the [SSL certificates](https://docs.aws.amazon.com/quickstart/latest/rd-gateway/architecture.html) that are rewuired for each RD Gateway instance.

The solution presented here uses [certbot](https://certbot.eff.org/about/) running as a [Lambda](https://aws.amazon.com/lambda/) function that gets a [Letsencrypt](https://letsencrypt.org/) SSL certificate that is good for 90 days. The certbot Lambda function runs on a schedule and gets a new SSL certificate every 60 days and saves the certificate in an S3 bucket. Upon receiving a new SSL certificate, the S3 bucket notifies an SQS queue so that the RD Gateway that listenes to that SQS queue every day is able to download the new certificate from S3 and install it on the RD Gateway server. This workflow ensures that the RD Gateway instance has a valid SSL certificate that is renenwed forever.

## Pre-requisites

* [Amazon Web Services (AWS) account](http://aws.amazon.com/).
* Terraform 0.13 installed on your computer. Check out HasiCorp [documentation](https://learn.hashicorp.com/terraform/azure/install) on how to install Terraform.

## Quick start

1. Configure your [AWS access 
keys](http://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html#access-keys-and-secret-access-keys) as 
environment variables:

```
$ export AWS_ACCESS_KEY_ID=(your access key id)
$ export AWS_SECRET_ACCESS_KEY=(your secret access key)
```

2. Clone this repository:

```
$ git clone https://github.com/RaduLupan/terraform-rdgateway-aws.git
$ cd terraform-rdgateway-aws
```
3. Optional: create a Virtual Private Cloud (VPC):

```
$ cd vpc
$ terraform init
$ terraform apply
```
4. Optional: create a Simple AD or Microsoft AD directory:

```
$ cd ad
$ terraform init
$ terraform apply
```

5. Create the letsencrypt-tls layer:

```
$ cd letsencrypt-tls
$ terraform init
$ terraform apply
```

6. Create the rd-gateway layer:

```
$ cd rd-gateway
$ terraform init
$ terraform apply
```

## Credits
Thank you [kingsoftgames](https://github.com/kingsoftgames/certbot-lambda) for your certbot-lambda implementation! I have found your code back in 2018 and have been running it at work ever since. Instead of manually renewing and installing the SSL certificates on a dozen RD Gateways we have in AWS, we have been receiving email notifications advising that the certificates have been renewed!