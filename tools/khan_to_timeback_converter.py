#!/usr/bin/env python3
"""
Khan Academy to TimeBack Format Converter

Converts scraped Khan Academy content to TimeBack/OneRoster format
for hosting on AWS and integration with the TimeBack platform.
"""

import json
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional
import argparse
import os

class KhanToTimeBackConverter:
    """Converts Khan Academy scraped content to TimeBack OneRoster format"""
    
    def __init__(self, organization_id: str = "khan-academy-converted"):
        self.organization_id = organization_id
        self.base_url = "https://your-aws-domain.com/api"  # Will be replaced with actual AWS URL
        
    def convert_khan_course(self, khan_json_path: str, output_dir: str) -> Dict[str, Any]:
        """Convert a Khan Academy JSON file to TimeBack format"""
        
        # Load Khan Academy scraped content
        with open(khan_json_path, 'r', encoding='utf-8') as f:
            khan_data = json.load(f)
        
        # Extract course data from GraphQL response
        course_data = self._extract_course_data(khan_data)
        
        # Create TimeBack course structure
        timeback_course = self._create_timeback_course(course_data)
        
        # Create syllabus with components
        syllabus = self._create_syllabus(course_data)
        
        # Save converted files
        output_files = self._save_converted_files(timeback_course, syllabus, output_dir)
        
        return {
            "course": timeback_course,
            "syllabus": syllabus,
            "output_files": output_files
        }
    
    def _extract_course_data(self, khan_data: Dict[str, Any]) -> Dict[str, Any]:
        """Extract course information from Khan Academy GraphQL response"""
        
        try:
            # Navigate Khan Academy's nested GraphQL structure
            content_route = khan_data["data"]["contentRoute"]["listedPathData"]
            course = content_route["course"]
            
            # Handle both course and unit structures
            if "unitChildren" in course:
                units = course["unitChildren"]
            else:
                # For single unit responses, wrap in array
                units = [course] if "allOrderedChildren" in course else []
            
            return {
                "id": course.get("id", str(uuid.uuid4())),
                "title": course.get("translatedTitle", "Khan Academy Course"),
                "description": course.get("translatedDescription", ""),
                "slug": course.get("slug", "khan-course"),
                "iconPath": course.get("iconPath", ""),
                "units": units,
                "subject": self._determine_subject(course.get("slug", "")),
                "gradeLevel": self._determine_grade_level(course.get("slug", ""))
            }
            
        except KeyError as e:
            print(f"Warning: Could not extract course data - {e}")
            # Return minimal structure
            return {
                "id": str(uuid.uuid4()),
                "title": "Khan Academy Course",
                "description": "Converted Khan Academy content",
                "slug": "khan-course",
                "iconPath": "",
                "units": [],
                "subject": "mathematics",
                "gradeLevel": "6-8"
            }
    
    def _create_timeback_course(self, course_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create TimeBack Course object"""
        
        course_id = str(uuid.uuid4())
        
        return {
            "sourcedId": course_id,
            "status": "active",
            "dateLastModified": datetime.now(timezone.utc).isoformat(),
            "title": course_data["title"],
            "courseCode": f"KHAN_{course_data['slug'].upper()}",
            "grades": [course_data["gradeLevel"]],
            "subjects": [course_data["subject"]],
            "org": {
                "sourcedId": self.organization_id,
                "type": "org"
            },
            "schoolYear": {
                "sourcedId": "2024-2025",
                "type": "academicSession"
            },
            "metadata": {
                "originalKhanId": course_data["id"],
                "originalSlug": course_data["slug"],
                "iconPath": course_data["iconPath"],
                "convertedFrom": "Khan Academy",
                "convertedAt": datetime.now(timezone.utc).isoformat()
            }
        }
    
    def _create_syllabus(self, course_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create TimeBack Syllabus with components"""
        
        course_id = str(uuid.uuid4())
        components = []
        
        # Convert each Khan Academy unit to a TimeBack component
        for unit_index, unit in enumerate(course_data["units"]):
            component = self._convert_unit_to_component(unit, unit_index)
            components.append(component)
        
        return {
            "course": {
                "sourcedId": course_id,
                "title": course_data["title"],
                "grades": [course_data["gradeLevel"]]
            },
            "subComponents": components
        }
    
    def _convert_unit_to_component(self, unit: Dict[str, Any], index: int) -> Dict[str, Any]:
        """Convert Khan Academy unit to TimeBack component"""
        
        component_id = str(uuid.uuid4())
        resources = []
        
        # Process unit's lessons/content
        if "allOrderedChildren" in unit:
            for child_index, child in enumerate(unit["allOrderedChildren"]):
                resource = self._convert_content_to_resource(child, child_index)
                if resource:
                    resources.append(resource)
        
        return {
            "sourcedId": component_id,
            "title": unit.get("translatedTitle", f"Unit {index + 1}"),
            "sortOrder": index,
            "subComponents": [],  # Khan units don't typically have sub-components
            "componentResources": resources,
            "metadata": {
                "originalKhanId": unit.get("id", ""),
                "originalSlug": unit.get("slug", ""),
                "unitType": "unit"
            }
        }
    
    def _convert_content_to_resource(self, content: Dict[str, Any], index: int) -> Optional[Dict[str, Any]]:
        """Convert Khan Academy content item to TimeBack resource"""
        
        content_kind = content.get("contentKind", "")
        content_type = content.get("__typename", "")
        
        if not content_kind and not content_type:
            return None
        
        resource_id = str(uuid.uuid4())
        resource_metadata = self._create_resource_metadata(content)
        
        return {
            "sourcedId": resource_id,
            "title": content.get("translatedTitle", content.get("title", f"Content {index + 1}")),
            "sortOrder": index,
            "resource": {
                "sourcedId": resource_id,
                "status": "active",
                "title": content.get("translatedTitle", content.get("title", f"Content {index + 1}")),
                "vendorResourceId": content.get("id", ""),
                "metadata": resource_metadata
            }
        }
    
    def _create_resource_metadata(self, content: Dict[str, Any]) -> Dict[str, Any]:
        """Create resource metadata based on Khan Academy content type"""
        
        content_kind = content.get("contentKind", "").lower()
        content_type = content.get("__typename", "").lower()
        
        metadata = {
            "originalKhanType": content_kind or content_type,
            "originalKhanId": content.get("id", ""),
            "description": content.get("translatedDescription", ""),
            "canonicalUrl": content.get("canonicalUrl", ""),
        }
        
        # Add time estimates if available
        if "timeEstimate" in content:
            time_est = content["timeEstimate"]
            metadata["estimatedDuration"] = {
                "lowerBound": time_est.get("lowerBound", 0),
                "upperBound": time_est.get("upperBound", 0)
            }
        
        # Determine TimeBack resource type and URL
        if content_kind == "video" or content_type == "video":
            metadata["type"] = "video"
            metadata["subType"] = "educational-video"
            # Use Khan Academy's video URL or construct YouTube URL
            if content.get("canonicalUrl"):
                metadata["url"] = f"https://www.khanacademy.org{content['canonicalUrl']}"
            
        elif content_kind == "exercise" or content_type == "exercise":
            metadata["type"] = "qti-assessment"
            metadata["subType"] = "qti-test"
            # Create URL to exercise
            if content.get("canonicalUrl"):
                metadata["url"] = f"https://www.khanacademy.org{content['canonicalUrl']}"
            
        elif content_kind == "article" or content_type == "article":
            metadata["type"] = "text"
            metadata["subType"] = "article"
            if content.get("canonicalUrl"):
                metadata["url"] = f"https://www.khanacademy.org{content['canonicalUrl']}"
            
        elif content_kind == "quiz" or content_type == "topicquiz":
            metadata["type"] = "qti-assessment"
            metadata["subType"] = "qti-quiz"
            if content.get("canonicalUrl"):
                metadata["url"] = f"https://www.khanacademy.org{content['canonicalUrl']}"
            
        else:
            # Default to text content
            metadata["type"] = "text"
            metadata["subType"] = "general-content"
            if content.get("canonicalUrl"):
                metadata["url"] = f"https://www.khanacademy.org{content['canonicalUrl']}"
        
        return metadata
    
    def _determine_subject(self, slug: str) -> str:
        """Determine subject from Khan Academy slug"""
        
        if "algebra" in slug or "math" in slug:
            return "mathematics"
        elif "science" in slug or "physics" in slug or "chemistry" in slug:
            return "science"
        elif "history" in slug:
            return "social-studies"
        elif "english" in slug or "grammar" in slug:
            return "language-arts"
        else:
            return "mathematics"  # Default
    
    def _determine_grade_level(self, slug: str) -> str:
        """Determine grade level from Khan Academy slug"""
        
        if "pre-algebra" in slug or "middle" in slug:
            return "6-8"
        elif "algebra2" in slug or "calculus" in slug or "high" in slug:
            return "9-12"
        elif "elementary" in slug or "arithmetic" in slug:
            return "K-5"
        else:
            return "6-8"  # Default
    
    def _save_converted_files(self, course: Dict[str, Any], syllabus: Dict[str, Any], output_dir: str) -> Dict[str, str]:
        """Save converted TimeBack files"""
        
        os.makedirs(output_dir, exist_ok=True)
        
        # Save course file
        course_file = os.path.join(output_dir, f"course_{course['sourcedId']}.json")
        with open(course_file, 'w', encoding='utf-8') as f:
            json.dump(course, f, indent=2, ensure_ascii=False)
        
        # Save syllabus file
        syllabus_file = os.path.join(output_dir, f"syllabus_{course['sourcedId']}.json")
        with open(syllabus_file, 'w', encoding='utf-8') as f:
            json.dump(syllabus, f, indent=2, ensure_ascii=False)
        
        # Create combined file for easy deployment
        combined_file = os.path.join(output_dir, f"timeback_course_{course['sourcedId']}.json")
        combined_data = {
            "course": course,
            "syllabus": syllabus,
            "convertedAt": datetime.now(timezone.utc).isoformat(),
            "version": "1.0"
        }
        
        with open(combined_file, 'w', encoding='utf-8') as f:
            json.dump(combined_data, f, indent=2, ensure_ascii=False)
        
        return {
            "course_file": course_file,
            "syllabus_file": syllabus_file,
            "combined_file": combined_file
        }

def main():
    """Command line interface for the converter"""
    
    parser = argparse.ArgumentParser(description="Convert Khan Academy content to TimeBack format")
    parser.add_argument("input_file", help="Path to Khan Academy JSON file")
    parser.add_argument("output_dir", help="Output directory for converted files")
    parser.add_argument("--org-id", default="khan-academy-converted", help="Organization ID for TimeBack")
    
    args = parser.parse_args()
    
    # Create converter
    converter = KhanToTimeBackConverter(organization_id=args.org_id)
    
    # Convert the file
    print(f"Converting {args.input_file} to TimeBack format...")
    
    try:
        result = converter.convert_khan_course(args.input_file, args.output_dir)
        
        print(f"✅ Conversion successful!")
        print(f"📁 Output files saved to: {args.output_dir}")
        print(f"📄 Course file: {result['output_files']['course_file']}")
        print(f"📄 Syllabus file: {result['output_files']['syllabus_file']}")
        print(f"📄 Combined file: {result['output_files']['combined_file']}")
        
        # Print summary
        course = result['course']
        syllabus = result['syllabus']
        component_count = len(syllabus['subComponents'])
        resource_count = sum(len(comp.get('componentResources', [])) for comp in syllabus['subComponents'])
        
        print(f"\n📊 Conversion Summary:")
        print(f"   Course: {course['title']}")
        print(f"   Components: {component_count}")
        print(f"   Resources: {resource_count}")
        print(f"   Grade Level: {course['grades'][0]}")
        print(f"   Subject: {course['subjects'][0]}")
        
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        raise

if __name__ == "__main__":
    main()