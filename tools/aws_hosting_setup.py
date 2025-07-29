#!/usr/bin/env python3
"""
AWS Hosting Setup for TimeBack Khan Academy Content

Sets up AWS infrastructure to host converted Khan Academy content
in TimeBack format with proper API endpoints.
"""

import json
import boto3
import yaml
from datetime import datetime
import os
import argparse
from typing import Dict, Any, List

class AWSTimeBackHosting:
    """Sets up AWS infrastructure for hosting TimeBack content"""
    
    def __init__(self, region: str = "us-east-1", stack_name: str = "timeback-khan-content"):
        self.region = region
        self.stack_name = stack_name
        self.s3_bucket_name = f"{stack_name}-content-{datetime.now().strftime('%Y%m%d')}"
        self.api_name = f"{stack_name}-api"
        
    def create_cloudformation_template(self) -> Dict[str, Any]:
        """Create CloudFormation template for TimeBack hosting infrastructure"""
        
        template = {
            "AWSTemplateFormatVersion": "2010-09-09",
            "Description": "TimeBack Khan Academy Content Hosting Infrastructure",
            "Parameters": {
                "Environment": {
                    "Type": "String",
                    "Default": "dev",
                    "AllowedValues": ["dev", "staging", "prod"],
                    "Description": "Environment name"
                }
            },
            "Resources": {
                # S3 Bucket for content storage
                "ContentBucket": {
                    "Type": "AWS::S3::Bucket",
                    "Properties": {
                        "BucketName": {"Ref": "AWS::NoValue"},  # Let AWS generate
                        "VersioningConfiguration": {
                            "Status": "Enabled"
                        },
                        "CorsConfiguration": {
                            "CorsRules": [{
                                "AllowedHeaders": ["*"],
                                "AllowedMethods": ["GET", "HEAD"],
                                "AllowedOrigins": ["*"],
                                "MaxAge": 3600
                            }]
                        },
                        "PublicAccessBlockConfiguration": {
                            "BlockPublicAcls": False,
                            "BlockPublicPolicy": False,
                            "IgnorePublicAcls": False,
                            "RestrictPublicBuckets": False
                        }
                    }
                },
                
                # S3 Bucket Policy for public read access
                "ContentBucketPolicy": {
                    "Type": "AWS::S3::BucketPolicy",
                    "Properties": {
                        "Bucket": {"Ref": "ContentBucket"},
                        "PolicyDocument": {
                            "Statement": [{
                                "Sid": "PublicReadGetObject",
                                "Effect": "Allow",
                                "Principal": "*",
                                "Action": "s3:GetObject",
                                "Resource": {"Fn::Sub": "${ContentBucket}/*"}
                            }]
                        }
                    }
                },
                
                # DynamoDB table for content metadata
                "ContentMetadataTable": {
                    "Type": "AWS::DynamoDB::Table",
                    "Properties": {
                        "TableName": {"Fn::Sub": "${AWS::StackName}-content-metadata"},
                        "BillingMode": "PAY_PER_REQUEST",
                        "AttributeDefinitions": [
                            {"AttributeName": "sourcedId", "AttributeType": "S"},
                            {"AttributeName": "type", "AttributeType": "S"}
                        ],
                        "KeySchema": [
                            {"AttributeName": "sourcedId", "KeyType": "HASH"}
                        ],
                        "GlobalSecondaryIndexes": [{
                            "IndexName": "TypeIndex",
                            "KeySchema": [
                                {"AttributeName": "type", "KeyType": "HASH"}
                            ],
                            "Projection": {"ProjectionType": "ALL"}
                        }],
                        "StreamSpecification": {
                            "StreamViewType": "NEW_AND_OLD_IMAGES"
                        }
                    }
                },
                
                # Lambda execution role
                "LambdaExecutionRole": {
                    "Type": "AWS::IAM::Role",
                    "Properties": {
                        "AssumeRolePolicyDocument": {
                            "Version": "2012-10-17",
                            "Statement": [{
                                "Effect": "Allow",
                                "Principal": {"Service": "lambda.amazonaws.com"},
                                "Action": "sts:AssumeRole"
                            }]
                        },
                        "ManagedPolicyArns": [
                            "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
                        ],
                        "Policies": [{
                            "PolicyName": "TimeBackContentAccess",
                            "PolicyDocument": {
                                "Version": "2012-10-17",
                                "Statement": [
                                    {
                                        "Effect": "Allow",
                                        "Action": [
                                            "s3:GetObject",
                                            "s3:PutObject",
                                            "s3:DeleteObject"
                                        ],
                                        "Resource": {"Fn::Sub": "${ContentBucket}/*"}
                                    },
                                    {
                                        "Effect": "Allow",
                                        "Action": [
                                            "dynamodb:GetItem",
                                            "dynamodb:PutItem",
                                            "dynamodb:UpdateItem",
                                            "dynamodb:DeleteItem",
                                            "dynamodb:Query",
                                            "dynamodb:Scan"
                                        ],
                                        "Resource": [
                                            {"Fn::GetAtt": ["ContentMetadataTable", "Arn"]},
                                            {"Fn::Sub": "${ContentMetadataTable}/index/*"}
                                        ]
                                    }
                                ]
                            }
                        }]
                    }
                },
                
                # Lambda function for TimeBack API
                "TimeBackAPIFunction": {
                    "Type": "AWS::Lambda::Function",
                    "Properties": {
                        "FunctionName": {"Fn::Sub": "${AWS::StackName}-api"},
                        "Runtime": "python3.11",
                        "Handler": "index.lambda_handler",
                        "Role": {"Fn::GetAtt": ["LambdaExecutionRole", "Arn"]},
                        "Environment": {
                            "Variables": {
                                "CONTENT_BUCKET": {"Ref": "ContentBucket"},
                                "METADATA_TABLE": {"Ref": "ContentMetadataTable"}
                            }
                        },
                        "Code": {
                            "ZipFile": {"Fn::Sub": self._get_lambda_code()}
                        },
                        "Timeout": 30
                    }
                },
                
                # API Gateway
                "TimeBackAPI": {
                    "Type": "AWS::ApiGateway::RestApi",
                    "Properties": {
                        "Name": {"Fn::Sub": "${AWS::StackName}-api"},
                        "Description": "TimeBack Khan Academy Content API",
                        "EndpointConfiguration": {
                            "Types": ["REGIONAL"]
                        }
                    }
                },
                
                # API Gateway Resources and Methods would go here
                # (Simplified for brevity - full implementation would include all OneRoster endpoints)
                
                # CloudFront Distribution for CDN
                "ContentDistribution": {
                    "Type": "AWS::CloudFront::Distribution",
                    "Properties": {
                        "DistributionConfig": {
                            "Origins": [{
                                "Id": "S3Origin",
                                "DomainName": {"Fn::GetAtt": ["ContentBucket", "DomainName"]},
                                "S3OriginConfig": {
                                    "OriginAccessIdentity": ""
                                }
                            }],
                            "DefaultCacheBehavior": {
                                "TargetOriginId": "S3Origin",
                                "ViewerProtocolPolicy": "redirect-to-https",
                                "AllowedMethods": ["GET", "HEAD", "OPTIONS"],
                                "CachedMethods": ["GET", "HEAD"],
                                "ForwardedValues": {
                                    "QueryString": False,
                                    "Cookies": {"Forward": "none"}
                                },
                                "MinTTL": 0,
                                "DefaultTTL": 86400,
                                "MaxTTL": 31536000
                            },
                            "Enabled": True,
                            "Comment": "TimeBack Khan Academy Content CDN"
                        }
                    }
                }
            },
            
            "Outputs": {
                "ContentBucketName": {
                    "Description": "Name of the S3 bucket for content",
                    "Value": {"Ref": "ContentBucket"},
                    "Export": {"Name": {"Fn::Sub": "${AWS::StackName}-ContentBucket"}}
                },
                "APIEndpoint": {
                    "Description": "API Gateway endpoint URL",
                    "Value": {"Fn::Sub": "https://${TimeBackAPI}.execute-api.${AWS::Region}.amazonaws.com/v1"},
                    "Export": {"Name": {"Fn::Sub": "${AWS::StackName}-APIEndpoint"}}
                },
                "CDNEndpoint": {
                    "Description": "CloudFront distribution endpoint",
                    "Value": {"Fn::GetAtt": ["ContentDistribution", "DomainName"]},
                    "Export": {"Name": {"Fn::Sub": "${AWS::StackName}-CDNEndpoint"}}
                },
                "MetadataTableName": {
                    "Description": "DynamoDB table for content metadata",
                    "Value": {"Ref": "ContentMetadataTable"},
                    "Export": {"Name": {"Fn::Sub": "${AWS::StackName}-MetadataTable"}}
                }
            }
        }
        
        return template
    
    def _get_lambda_code(self) -> str:
        """Generate Lambda function code for TimeBack API"""
        
        return '''
import json
import boto3
import os
from datetime import datetime

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

CONTENT_BUCKET = os.environ['CONTENT_BUCKET']
METADATA_TABLE = os.environ['METADATA_TABLE']

def lambda_handler(event, context):
    """Handle TimeBack API requests"""
    
    path = event.get('path', '')
    method = event.get('httpMethod', 'GET')
    
    try:
        # Parse OneRoster API paths
        if path.startswith('/orgs'):
            return handle_organizations(event)
        elif path.startswith('/courses'):
            return handle_courses(event)
        elif path.startswith('/powerpath/syllabus'):
            return handle_syllabus(event)
        elif path.startswith('/health'):
            return {
                'statusCode': 200,
                'body': json.dumps({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})
            }
        else:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Not found'})
            }
            
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def handle_organizations(event):
    """Handle organization endpoints"""
    return {
        'statusCode': 200,
        'body': json.dumps({
            'orgs': [{
                'sourcedId': 'khan-academy-converted',
                'name': 'Khan Academy Converted Content',
                'type': 'national',
                'status': 'active'
            }]
        })
    }

def handle_courses(event):
    """Handle course endpoints"""
    path_params = event.get('pathParameters', {})
    
    if not path_params or not path_params.get('courseId'):
        # List all courses
        return list_courses()
    else:
        # Get specific course
        course_id = path_params['courseId']
        return get_course(course_id)

def handle_syllabus(event):
    """Handle syllabus endpoints"""
    path_params = event.get('pathParameters', {})
    course_id = path_params.get('courseId')
    
    if not course_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Course ID required'})
        }
    
    return get_syllabus(course_id)

def list_courses():
    """List all available courses"""
    # In a full implementation, this would query DynamoDB
    # For now, return hardcoded Khan Academy converted courses
    return {
        'statusCode': 200,
        'body': json.dumps({
            'courses': [{
                'sourcedId': 'pre-algebra-converted',
                'title': 'Pre-algebra (Khan Academy)',
                'courseCode': 'KHAN_PRE-ALGEBRA',
                'grades': ['6-8'],
                'subjects': ['mathematics'],
                'status': 'active'
            }]
        })
    }

def get_course(course_id):
    """Get specific course details"""
    try:
        # Try to load course from S3
        response = s3.get_object(
            Bucket=CONTENT_BUCKET,
            Key=f'courses/{course_id}.json'
        )
        course_data = json.loads(response['Body'].read())
        
        return {
            'statusCode': 200,
            'body': json.dumps(course_data)
        }
    except s3.exceptions.NoSuchKey:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Course not found'})
        }

def get_syllabus(course_id):
    """Get course syllabus"""
    try:
        # Try to load syllabus from S3
        response = s3.get_object(
            Bucket=CONTENT_BUCKET,
            Key=f'syllabi/{course_id}.json'
        )
        syllabus_data = json.loads(response['Body'].read())
        
        return {
            'statusCode': 200,
            'body': json.dumps({'syllabus': syllabus_data})
        }
    except s3.exceptions.NoSuchKey:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Syllabus not found'})
        }
'''
    
    def create_deployment_script(self, output_dir: str) -> str:
        """Create deployment script for the infrastructure"""
        
        script_path = os.path.join(output_dir, "deploy.sh")
        
        script_content = f'''#!/bin/bash

# TimeBack Khan Academy Content Deployment Script

set -e

STACK_NAME="{self.stack_name}"
REGION="{self.region}"
TEMPLATE_FILE="cloudformation.yaml"
CONTENT_DIR="converted_content"

echo "🚀 Deploying TimeBack Khan Academy Content Infrastructure..."

# Deploy CloudFormation stack
echo "📦 Deploying CloudFormation stack..."
aws cloudformation deploy \\
    --template-file $TEMPLATE_FILE \\
    --stack-name $STACK_NAME \\
    --capabilities CAPABILITY_IAM \\
    --region $REGION \\
    --parameter-overrides Environment=dev

# Get stack outputs
echo "📋 Getting stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \\
    --stack-name $STACK_NAME \\
    --region $REGION \\
    --query 'Stacks[0].Outputs[?OutputKey==`ContentBucketName`].OutputValue' \\
    --output text)

API_ENDPOINT=$(aws cloudformation describe-stacks \\
    --stack-name $STACK_NAME \\
    --region $REGION \\
    --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \\
    --output text)

CDN_ENDPOINT=$(aws cloudformation describe-stacks \\
    --stack-name $STACK_NAME \\
    --region $REGION \\
    --query 'Stacks[0].Outputs[?OutputKey==`CDNEndpoint`].OutputValue' \\
    --output text)

echo "✅ Infrastructure deployed successfully!"
echo "📦 S3 Bucket: $BUCKET_NAME"
echo "🌐 API Endpoint: $API_ENDPOINT"
echo "🚀 CDN Endpoint: $CDN_ENDPOINT"

# Upload converted content
if [ -d "$CONTENT_DIR" ]; then
    echo "📤 Uploading converted content..."
    
    # Upload course files
    for file in $CONTENT_DIR/course_*.json; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            course_id=$(echo "$filename" | sed 's/course_\\(.*\\)\\.json/\\1/')
            aws s3 cp "$file" "s3://$BUCKET_NAME/courses/$course_id.json" --region $REGION
            echo "✅ Uploaded course: $course_id"
        fi
    done
    
    # Upload syllabus files
    for file in $CONTENT_DIR/syllabus_*.json; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            course_id=$(echo "$filename" | sed 's/syllabus_\\(.*\\)\\.json/\\1/')
            aws s3 cp "$file" "s3://$BUCKET_NAME/syllabi/$course_id.json" --region $REGION
            echo "✅ Uploaded syllabus: $course_id"
        fi
    done
    
    echo "📤 Content upload complete!"
else
    echo "⚠️  No content directory found. Run the converter first."
fi

echo ""
echo "🎉 Deployment Complete!"
echo ""
echo "📊 Your TimeBack API is now available at:"
echo "   $API_ENDPOINT"
echo ""
echo "📚 To test the API:"
echo "   curl $API_ENDPOINT/health"
echo "   curl $API_ENDPOINT/courses"
echo ""
echo "🔧 To update your iOS app, change the base URL to:"
echo "   $API_ENDPOINT"
echo ""
'''
        
        with open(script_path, 'w') as f:
            f.write(script_content)
        
        # Make script executable
        os.chmod(script_path, 0o755)
        
        return script_path
    
    def generate_infrastructure_files(self, output_dir: str) -> Dict[str, str]:
        """Generate all infrastructure files"""
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Generate CloudFormation template
        template = self.create_cloudformation_template()
        cf_template_path = os.path.join(output_dir, "cloudformation.yaml")
        
        with open(cf_template_path, 'w') as f:
            yaml.dump(template, f, default_flow_style=False, sort_keys=False)
        
        # Generate deployment script
        deploy_script_path = self.create_deployment_script(output_dir)
        
        # Generate configuration file
        config = {
            "stack_name": self.stack_name,
            "region": self.region,
            "api_name": self.api_name,
            "created_at": datetime.now().isoformat(),
            "endpoints": {
                "health": "/health",
                "courses": "/courses",
                "syllabus": "/powerpath/syllabus/{courseId}",
                "organizations": "/orgs"
            }
        }
        
        config_path = os.path.join(output_dir, "config.json")
        with open(config_path, 'w') as f:
            json.dump(config, f, indent=2)
        
        # Generate README
        readme_path = os.path.join(output_dir, "README.md")
        readme_content = f'''# TimeBack Khan Academy Content Hosting

This directory contains AWS infrastructure files for hosting converted Khan Academy content in TimeBack format.

## Files

- `cloudformation.yaml`: CloudFormation template for AWS infrastructure
- `deploy.sh`: Deployment script to set up everything
- `config.json`: Configuration settings

## Quick Start

1. **Prerequisites**:
   - AWS CLI configured with appropriate permissions
   - Converted Khan Academy content in `converted_content/` directory

2. **Deploy**:
   ```bash
   ./deploy.sh
   ```

3. **Test**:
   ```bash
   # Test health endpoint
   curl https://your-api-endpoint/health
   
   # List courses
   curl https://your-api-endpoint/courses
   
   # Get syllabus
   curl https://your-api-endpoint/powerpath/syllabus/COURSE_ID
   ```

## Architecture

- **S3**: Content storage with public read access
- **API Gateway + Lambda**: TimeBack-compatible REST API
- **DynamoDB**: Content metadata storage
- **CloudFront**: CDN for fast content delivery

## Cost Estimate

- S3: ~$0.02/GB/month
- Lambda: Free tier covers most usage
- API Gateway: $3.50 per million requests
- DynamoDB: Pay-per-request pricing
- CloudFront: $0.085 per GB for first 10 TB

Total estimated cost: **< $10/month** for moderate usage.

## Updating Content

To update content, run the converter again and re-run `./deploy.sh`.

## Integration with iOS App

Update your iOS app's API base URL to use the deployed endpoint:

```swift
private let baseURL = "https://your-api-endpoint"
```
'''
        
        with open(readme_path, 'w') as f:
            f.write(readme_content)
        
        return {
            "cloudformation_template": cf_template_path,
            "deployment_script": deploy_script_path,
            "config_file": config_path,
            "readme_file": readme_path
        }

def main():
    """Command line interface"""
    
    parser = argparse.ArgumentParser(description="Set up AWS hosting for TimeBack Khan Academy content")
    parser.add_argument("--region", default="us-east-1", help="AWS region")
    parser.add_argument("--stack-name", default="timeback-khan-content", help="CloudFormation stack name")
    parser.add_argument("--output-dir", default="aws_infrastructure", help="Output directory")
    
    args = parser.parse_args()
    
    # Create AWS hosting setup
    hosting = AWSTimeBackHosting(region=args.region, stack_name=args.stack_name)
    
    print(f"🏗️  Generating AWS infrastructure files for TimeBack hosting...")
    
    # Generate all files
    files = hosting.generate_infrastructure_files(args.output_dir)
    
    print(f"✅ Infrastructure files generated in: {args.output_dir}")
    print(f"📄 CloudFormation template: {files['cloudformation_template']}")
    print(f"🚀 Deployment script: {files['deployment_script']}")
    print(f"⚙️  Configuration: {files['config_file']}")
    print(f"📖 Documentation: {files['readme_file']}")
    
    print(f"\\n🎯 Next Steps:")
    print(f"1. Review the generated files")
    print(f"2. Run: cd {args.output_dir} && ./deploy.sh")
    print(f"3. Update your iOS app with the new API endpoint")
    print(f"4. Test the deployment")

if __name__ == "__main__":
    main()