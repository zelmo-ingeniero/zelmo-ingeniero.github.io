
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

iam.yaml content

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Description: Creating IAM resources

Parameters:
  IamNameTag:
    Description: This name will be only in iam resources
    Type: String
    Default: first

Transform: AWS::LanguageExtensions

Resources:
  thisIamGroup:
    Type: AWS::IAM::Group
    Properties:
      GroupName: !Join
        - ''
        - - my
          - !Ref IamNameTag
          - Group
      Path: /

  Fn::ForEach::iamUsersToGroup:
    - userName
    - - userOne
      - userTwo
      - userThree
    - thisIam${userName}:
        Type: AWS::IAM::User
        Properties:
          UserName: !Ref userName
          Groups:
            - !Ref thisIamGroup
          LoginProfile:
            Password: b98*uU723465
            PasswordResetRequired: true
          ManagedPolicyArns:
            - arn:aws:iam::aws:policy/IAMUserChangePassword
          Tags:
            - Key: Name
              Value: !Join
                - ''
                - -  !Ref IamNameTag
                  -  !Ref userName

Outputs:
  currentAccount:
    Description: The ID of the AWS account
    Value: !Ref AWS::AccountId
  currentRegion:
    Description: The region of the stack and their resources
    Value: !Ref AWS::Region
  currentStack:
    Description: The region of the stack and their resources
    Value: !Ref AWS::StackName
  iamGroupArn:
    Description: The user group ARN
    Value: !GetAtt thisIamGroup.Arn
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  iamGroupArn
  username1:
    Description: The user 1 ARN
    Value: !GetAtt thisIamuserOne.Arn
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  thisIamuserOne
  username2:
    Description: The user 2 ARN
    Value: !GetAtt thisIamuserTwo.Arn
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  thisIamuserTwo
  username3:
    Description: The user 3 ARN
    Value: !GetAtt thisIamuserThree.Arn
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  thisIamuserThree
```

vpc.yaml content


```yaml
AWSTemplateFormatVersion: '2010-09-09'

Description: Creating just VPC resources

Parameters:
  VpcTag:
    Description: This name will be only in the vpc resources
    Type: String
    Default: module-vpc
  VpcCidr:
    Description: This name will be only in the vpc resources
    Type: String
    Default: 10.0.0.0/16

Resources:
  thisVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      Tags:
        - Key: Name
          Value: !Ref VpcTag

  thisSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      VpcId: !Ref thisVpc
      GroupDescription: created with cf
      GroupName: !Ref VpcTag
      SecurityGroupEgress:
        - CidrIp: 0.0.0.0/0
          Description: Enable all of the traffic
          FromPort: 0
          ToPort: 0
          IpProtocol: -1
      SecurityGroupIngress:
        - CidrIp: 0.0.0.0/0
          Description: Inbound to ssh
          FromPort: 22
          ToPort: 22
          IpProtocol: TCP
      Tags:
        - Key: Name
          Value: !Ref VpcTag

Outputs:
  currentAccount:
    Description: The ID of the AWS account
    Value: !Ref AWS::AccountId
  currentRegion:
    Description: The region of the stack and their resources
    Value: !Ref AWS::Region
  currentStack:
    Description: The region of the stack and their resources
    Value: !Ref AWS::StackName

  vpcCidr:
    Description: The cidr of the VPC
    Value: !GetAtt thisVpc.CidrBlock
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  VpcCidr
  vpcDefaultSecurityGroup:
    Description: The default security group of the VPC
    Value: !GetAtt thisVpc.DefaultSecurityGroup
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  vpcDefaultSecurityGroup
  vpcId:
    Description: The vpc ID
    Value: !Ref thisVpc
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  vpcId
  vpcSgpId:
    Description: The ID of the security group
    Value: !GetAtt thisSecurityGroup.GroupId
    Export:
      Name: !Join
        - ''
        - -  !Ref AWS::StackName
          -  vpcSgpId
```

stack.yaml content

```yaml
AWSTemplateFormatVersion: '2010-09-09'

Description: Base module with nested stacks

Parameters:
  GlobalNameTag:
    Description: This name will be in all of the resource name tags
    Type: String
    Default: base
Resources:
  iamModule:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL: 
      Parameters:
        IamNameTag: first
      # StackName: myCustomNaming01

  vpcModule:
    Type: AWS::CloudFormation::Stack
    Properties:
      TemplateURL:
      Parameters:
        VpcTag: second
      # StackName: myCustomNaming02

Outputs:
  currentAccount:
    Description: The ID of the AWS account
    Value: !Ref AWS::AccountId
  currentRegion:
    Description: The region of the stack and their resources
    Value: !Ref AWS::Region
  currentRegion:
    Description: The region of the stack and their resources
    Value: !Ref AWS::Region

  iamModuleGroupArn:
    Description: The group arn from iam embeded stack
    Value: !GetAtt iamModule.Outputs.iamGroupArn
  iamModuleusername1Arn:
    Description: The 1 username from iam embeded stack
    Value: !GetAtt iamModule.Outputs.username1
  iamModuleusername2Arn:
    Description: The 2 username from iam embeded stack
    Value: !GetAtt iamModule.Outputs.username2
  iamModuleusername3Arn:
    Description: The 3 username from iam embeded stack
    Value: !GetAtt iamModule.Outputs.username3

  vpcModuleCidr:
    Description: The cidr of the VPC from vpc embeded stack
    Value: !GetAtt vpcModule.Outputs.vpcCidr
  vpcModuleDefaultSecurityGroup:
    Description: The default security group of the VPC from vpc embeded stack
    Value: !GetAtt vpcModule.Outputs.vpcDefaultSecurityGroup
  vpcModuleId:
    Description: The vpc ID from vpc embeded stack
    Value: !GetAtt vpcModule.Outputs.vpcId
  vpcModuleSgpId:
    Description: The ID of the security group from vpc embeded stack
    Value: !GetAtt vpcModule.Outputs.vpcSgpId

  moduleIamArn:
    Description: The iam embeded stack name
    Value: !Ref iamModule
  moduleVpcArn:
    Description: The vpc embeded stack name
    Value: !Ref vpcModule

```
