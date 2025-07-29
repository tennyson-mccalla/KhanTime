# TimeBack Khan Academy Content Hosting

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
