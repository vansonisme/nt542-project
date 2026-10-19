# NT542 AWS Infrastructure Setup

This tutorial deploys the infrastructure defined in `Cloudformation.yaml`:

- One VPC
- One public subnet with an Apache load-balancer EC2 instance
- Two private subnets with one Apache worker EC2 instance in each subnet
- One Internet Gateway
- One NAT Gateway shared by the private subnets
- Security groups for HTTP and SSH

The examples use AWS Region `us-east-1` and stack name `nt542-project`.

## Prerequisites

- An AWS account with permission to use CloudFormation, EC2, VPC, Elastic IP, NAT Gateway, and SSM public parameters.
- An existing EC2 key pair in `us-east-1`, for example `NT542v2`.
- The private key file for that key pair, for example `NT542v2.pem`.
- `Cloudformation.yaml` downloaded or cloned to your computer.

> `KeyName` is the AWS key-pair name (`NT542v2`), not the local filename (`NT542v2.pem`). NAT Gateway and EC2 resources incur AWS charges.

## Option 1: Deploy with the AWS Console

1. Sign in to the AWS Console and select **US East (N. Virginia) — us-east-1**.
2. Open **CloudFormation** and choose **Create stack** → **With new resources (standard)**.
3. Select **Upload a template file**, upload `Cloudformation.yaml`, and choose **Next**.
4. Enter stack name `nt542-project`.
5. Set the parameters:
   - `InstanceType`: `t3.micro`
   - `KeyName`: your existing EC2 key-pair name, such as `NT542v2`
   - `SSHLocation`: your public IP in CIDR format, such as `203.0.113.10/32`
6. Keep the remaining settings at their defaults and choose **Submit**.
7. Wait until the stack status becomes `CREATE_COMPLETE`.
8. Open the **Outputs** tab and visit the `WebsiteURL` value.

## Option 2: Deploy with AWS CLI (Linux)

Configure and verify AWS CLI credentials:

```bash
aws configure
aws sts get-caller-identity
```

Confirm that the key pair exists in the deployment Region:

```bash
aws ec2 describe-key-pairs \
  --key-names NT542v2 \
  --region us-east-1
```

Validate the template:

```bash
aws cloudformation validate-template \
  --template-body file://Cloudformation.yaml \
  --region us-east-1
```

Create or update the stack:

```bash
aws cloudformation deploy \
  --template-file Cloudformation.yaml \
  --stack-name nt542-project \
  --region us-east-1 \
  --parameter-overrides \
    InstanceType=t3.micro \
    KeyName=NT542v2 \
  --no-fail-on-empty-changeset
```

## View Stack Outputs and EC2 Addresses

Display the CloudFormation outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name nt542-project \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' \
  --output table
```

Display the public and private addresses of the EC2 instances:

```bash
aws ec2 describe-instances \
  --region us-east-1 \
  --filters 'Name=tag:aws:cloudformation:stack-name,Values=nt542-project' \
  --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,PrivateIpAddress,PublicIpAddress,State.Name]' \
  --output table
```

The load-balancer instance has a public IP. The two worker instances only have private IPs and use the NAT Gateway for outbound Internet access.

## Delete the Infrastructure

Delete the stack when it is no longer needed:

```bash
aws cloudformation delete-stack \
  --stack-name nt542-project \
  --region us-east-1

aws cloudformation wait stack-delete-complete \
  --stack-name nt542-project \
  --region us-east-1
```

The existing EC2 key pair and your local `.pem` file are not deleted because they were not created by this stack.
****
