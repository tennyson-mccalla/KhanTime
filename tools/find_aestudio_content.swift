#!/usr/bin/swift

import Foundation

// Simple script to explore what's available in TimeBack staging
print("🔍 TimeBack Content Discovery")
print("=====================================")

print("\n📋 API Endpoints to explore for ae.studio 3rd grade language content:")
print("1. GET /ims/oneroster/rostering/v1p2/courses")
print("2. GET /ims/oneroster/rostering/v1p2/orgs") 
print("3. GET /ims/oneroster/rostering/v1p2/resources")
print("4. GET /powerpath/syllabus/{courseId}")

print("\n🎯 Search strategies:")
print("- Look for course titles containing: 'language', 'english', 'reading', 'grade', '3rd'")
print("- Find ae.studio organization ID")
print("- Filter courses by organization")
print("- Examine PowerPath syllabi for content structure")

print("\n💡 Key questions for Andy Montgomery if this doesn't work:")
print("1. What is the exact course ID or title for ae.studio's 3rd grade language content?")
print("2. What organization ID should we filter by for ae.studio content?")
print("3. Are there specific PowerPath course IDs we should use?")
print("4. Should we look in production instead of staging?")

print("\n🚀 Next: Integrate this search into the existing KhanTime CourseService")