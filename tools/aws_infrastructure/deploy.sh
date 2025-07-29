#!/bin/bash

# TimeBack Khan Academy Content Deployment Script

set -e

STACK_NAME="timeback-khan-content"
REGION="us-east-1"
TEMPLATE_FILE="cloudformation.yaml"
CONTENT_DIR="converted_content"

echo "🚀 Deploying TimeBack Khan Academy Content Infrastructure..."

# Deploy CloudFormation stack
echo "📦 Deploying CloudFormation stack..."
aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --capabilities CAPABILITY_IAM \
    --region $REGION \
    --parameter-overrides Environment=dev

# Get stack outputs
echo "📋 Getting stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`ContentBucketName`].OutputValue' \
    --output text)

API_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
    --output text)

CDN_ENDPOINT=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`CDNEndpoint`].OutputValue' \
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
            course_id=$(echo "$filename" | sed 's/course_\(.*\)\.json/\1/')
            aws s3 cp "$file" "s3://$BUCKET_NAME/courses/$course_id.json" --region $REGION
            echo "✅ Uploaded course: $course_id"
        fi
    done
    
    # Upload syllabus files
    for file in $CONTENT_DIR/syllabus_*.json; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            course_id=$(echo "$filename" | sed 's/syllabus_\(.*\)\.json/\1/')
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
