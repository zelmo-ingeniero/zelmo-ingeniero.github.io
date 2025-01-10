
# S3 and cloudformation Commands

## Prerequisites

- AWS CLI installed

As a recomendation, the template files should be stored in 1 S3 bucket (or more buckets if necessary)

## Upload .yml files to the bucket

- Upload a yaml to the S3 

> if the file already exists, it updates and the URL doesn't change

```bash
aws s3 cp stack.yaml s3://my-cf-templates/
```

- List S3 content

```bash
aws s3 ls my-ct-templates
```

Once a template `.yaml` file is uploaded to an S3 the URLs of the object are:
  - url: https://<bucket-name>.s3.us-east-1.amazonaws.com/<filename>
  - uri: s3://<bucket-name>/<filename>

## Cloudformation

List active stacks

```bash
aws cloudformation list-stacks --stack-status-filter CREATE_IN_PROGRESS CREATE_COMPLETE ROLLBACK_IN_PROGRESS ROLLBACK_COMPLETE
```

Delete existing stack

```bash
aws cloudformation delete-stack --stack-name <the-name-of-the-stack> --deletion-mode FORCE_DELETE_STACK
```

Create a new stack that creates IAM roles and have `foreach` expressions (IAM and `foreach` expresions requires more parameters)

```bash
aws cloudformation create-stack  --stack-name root --template-url https://my-ct-templates.s3.us-east-1.amazonaws.com/stack.yaml --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND --tags Key=Name,Value=rootModule
```