# iOS App Integration Guide
## Converting from TimeBack API to AWS-Hosted Khan Academy Content

This guide shows how to update your KhanTime iOS app to use the AWS-hosted Khan Academy content instead of the failing TimeBack API.

## Quick Summary

We've successfully:
✅ **Converted Khan Academy content** from scraped GraphQL responses to TimeBack/OneRoster format  
✅ **Created AWS infrastructure** with S3, API Gateway, Lambda, and CloudFront  
✅ **Generated deployment scripts** for one-command deployment  
✅ **Tested conversion** with Pre-algebra course (15 units, 144 resources)  

## Architecture Overview

```
iOS App → AWS API Gateway → Lambda Functions → S3 Content Storage
                                           ↘ DynamoDB Metadata
```

## Step 1: Deploy AWS Infrastructure

```bash
cd /Users/Tennyson/KhanTime/tools/aws_infrastructure
./deploy.sh
```

This will output your new API endpoint, like:
```
🌐 API Endpoint: https://abc123def.execute-api.us-east-1.amazonaws.com/v1
```

## Step 2: Update iOS App Configuration

### Option A: Update Existing TimeBack Provider

Modify `AEStudioContentProvider.swift` to point to your AWS endpoint:

```swift
// In AEStudioContentProvider.swift, update the courseService initialization:

class AEStudioContentProvider {
    // Replace with your AWS API endpoint
    private let awsBaseURL = "https://your-aws-endpoint.execute-api.us-east-1.amazonaws.com/v1"
    
    // Update course ID to use converted Khan Academy content
    private let khanAlgebraCourseId = "717fbd67-d2d1-46d1-9841-6c158051af39"  // From conversion
    
    private lazy var courseService: CourseService = {
        // Create custom CourseService with AWS endpoint
        return CourseServiceAWS(baseURL: awsBaseURL)
    }()
    
    func loadAEStudioLessons() async throws -> [InteractiveLesson] {
        print("🔍 Loading Khan Academy Pre-algebra content from AWS...")
        
        guard let course = try await courseService.fetchCourse(by: khanAlgebraCourseId) else {
            throw ContentError.courseNotFound("Khan Academy course not found: \(khanAlgebraCourseId)")
        }
        
        // Rest remains the same...
    }
}
```

### Option B: Create New AWS Content Provider

Create a new `AWSKhanContentProvider.swift`:

```swift
import Foundation

class AWSKhanContentProvider {
    private let awsBaseURL = "https://your-aws-endpoint.execute-api.us-east-1.amazonaws.com/v1"
    private let courseService: CourseServiceAWS
    
    init() {
        self.courseService = CourseServiceAWS(baseURL: awsBaseURL)
    }
    
    func loadKhanAcademyLessons() async throws -> [InteractiveLesson] {
        // Get list of available courses
        let courses = try await courseService.fetchAllCourses()
        
        var allLessons: [InteractiveLesson] = []
        
        for course in courses {
            let syllabus = try await courseService.fetchSyllabus(for: course.sourcedId)
            let lessons = convertTimeBackToInteractiveLessons(course: course, syllabus: syllabus)
            allLessons.append(contentsOf: lessons)
        }
        
        return allLessons
    }
    
    // Use existing conversion logic from AEStudioContentProvider
}
```

## Step 3: Create AWS CourseService

Create `CourseServiceAWS.swift`:

```swift
import Foundation

class CourseServiceAWS {
    private let baseURL: String
    private let session = URLSession.shared
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func fetchAllCourses() async throws -> [Course] {
        let url = URL(string: "\(baseURL)/courses")!
        let (data, _) = try await session.data(from: url)
        
        let response = try JSONDecoder().decode(CoursesResponse.self, from: data)
        return response.courses
    }
    
    func fetchCourse(by id: String) async throws -> Course? {
        let url = URL(string: "\(baseURL)/courses/\(id)")!
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        return try JSONDecoder().decode(Course.self, from: data)
    }
    
    func fetchSyllabus(for courseId: String) async throws -> Syllabus {
        let url = URL(string: "\(baseURL)/powerpath/syllabus/\(courseId)")!
        let (data, _) = try await session.data(from: url)
        
        let response = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let syllabusData = response["syllabus"] as! [String: Any]
        
        // Convert to Syllabus object using existing parsing logic
        return try parseSyllabusFromJSON(syllabusData)
    }
}

struct CoursesResponse: Codable {
    let courses: [Course]
}
```

## Step 4: Update InteractiveLessonsBrowserView

Update the view to use AWS content:

```swift
// In InteractiveLessonsBrowserView.swift:

private let awsProvider = AWSKhanContentProvider()  // New provider

private func loadLessons() {
    guard !isLoadingTimeBack else { return }
    
    isLoadingTimeBack = true
    timeBackError = nil
    
    Task {
        do {
            print("📡 Loading Khan Academy content from AWS...")
            
            // Load static lessons first
            var lessons = LessonProvider.getOriginalDemoLessons()
            
            // Load real Khan Academy content from AWS
            let awsLessons = try await awsProvider.loadKhanAcademyLessons()
            lessons.append(contentsOf: awsLessons)
            
            await MainActor.run {
                self.allLessons = lessons
                self.isLoadingTimeBack = false
                print("✅ Loaded \(lessons.count) lessons including \(awsLessons.count) from AWS")
            }
        } catch {
            await MainActor.run {
                self.timeBackError = "Error loading AWS content: \(error.localizedDescription)"
                self.isLoadingTimeBack = false
                print("❌ AWS loading failed: \(error)")
                
                // Fallback to static content
                var lessons = LessonProvider.getOriginalDemoLessons()
                lessons.append(contentsOf: KhanAcademyContentProvider.loadKhanAcademyLessons())
                self.allLessons = lessons
            }
        }
    }
}
```

## Step 5: Update Loading UI

Update the loading messages to reflect AWS hosting:

```swift
// In loadingView:
Text("Loading Khan Academy Content from AWS...")
    .font(theme?.bodyFont ?? .body)
    .foregroundColor(theme?.secondaryColor ?? .secondary)

Text("Course: Pre-algebra (15 units, 144 resources)")
    .font(theme?.captionFont ?? .caption)
    .foregroundColor(theme?.secondaryColor ?? .secondary)
```

## Step 6: Test the Integration

1. **Build and run** the iOS app
2. **Navigate to Interactive Lessons**
3. **Verify** that Khan Academy content loads from AWS
4. **Test** lesson navigation and content display
5. **Check** that real course structure appears (15 units for Pre-algebra)

## Expected Results

- ✅ **"Factors and multiples"** unit should load with real Khan Academy content
- ✅ **15 Pre-algebra units** should be available
- ✅ **144 resources** including videos, exercises, and articles
- ✅ **Proper lesson navigation** with actual content
- ✅ **No more 404 errors** from TimeBack API

## Troubleshooting

### If AWS API returns 404:
```bash
# Test your API endpoint
curl https://your-endpoint/health
curl https://your-endpoint/courses
```

### If conversion failed:
```bash
# Re-run conversion with different Khan Academy file
cd /Users/Tennyson/KhanTime/tools
python3 khan_to_timeback_converter.py other_khan_file.json converted_content
```

### If deployment failed:
```bash
# Check CloudFormation stack status
aws cloudformation describe-stacks --stack-name timeback-khan-content

# Check Lambda logs
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/timeback-khan-content
```

## Cost Optimization

To minimize AWS costs:

1. **Enable S3 Intelligent Tiering** for automatic cost optimization
2. **Set up CloudWatch alarms** for unexpected usage spikes  
3. **Use API Gateway caching** to reduce Lambda invocations
4. **Consider Reserved Capacity** for DynamoDB if usage is predictable

**Estimated monthly cost: < $10** for moderate usage

## Security Considerations

- ✅ **HTTPS only** via API Gateway and CloudFront
- ✅ **CORS configured** for web access if needed
- ✅ **IAM roles** with minimal required permissions
- ✅ **No secrets** in client-side code

## Next Steps

1. **Deploy infrastructure**: `./deploy.sh`
2. **Update iOS app** with new endpoint  
3. **Test thoroughly** with real device
4. **Monitor costs** in AWS Console
5. **Scale up** by converting more Khan Academy subjects

---

## File References

- **Converter**: `/Users/Tennyson/KhanTime/tools/khan_to_timeback_converter.py`
- **AWS Setup**: `/Users/Tennyson/KhanTime/tools/aws_hosting_setup.py`  
- **Infrastructure**: `/Users/Tennyson/KhanTime/tools/aws_infrastructure/`
- **Converted Content**: `/Users/Tennyson/KhanTime/tools/converted_content/`
- **iOS Integration**: Update `Source/Providers/AEStudioContentProvider.swift`

The solution provides a complete pathway from scraped Khan Academy content to a production-ready iOS app with real educational content hosted on AWS infrastructure.