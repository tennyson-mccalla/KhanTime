import Foundation

// MARK: - Robust Data Parser
// Service to handle malformed API data gracefully

class RobustDataParser {
    
    // MARK: - Course Parsing
    
    /// Parses courses from potentially malformed JSON data
    static func parseCourses(from data: Data) -> [Course] {
        var parsedCourses: [Course] = []
        
        do {
            // First try normal JSON decoding
            let decoder = JSONDecoder()
            let response = try decoder.decode(CourseListResponse.self, from: data)
            return response.courses
            
        } catch {
            print("⚠️ Standard JSON decoding failed: \(error)")
            print("🔧 Attempting robust manual parsing...")
            
            // Fall back to manual parsing with error tolerance
            return manuallyParseCourses(from: data)
        }
    }
    
    /// Manually parses courses with graceful error handling
    private static func manuallyParseCourses(from data: Data) -> [Course] {
        var parsedCourses: [Course] = []
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let coursesArray = json["courses"] as? [[String: Any]] else {
                print("❌ Could not extract courses array from JSON")
                return []
            }
            
            for (index, courseDict) in coursesArray.enumerated() {
                if let course = safelyParseCourse(from: courseDict, index: index) {
                    parsedCourses.append(course)
                }
            }
            
            print("✅ Manually parsed \(parsedCourses.count) out of \(coursesArray.count) courses")
            
        } catch {
            print("❌ JSON serialization failed: \(error)")
        }
        
        return parsedCourses
    }
    
    /// Safely parses a single course with extensive error handling
    private static func safelyParseCourse(from dict: [String: Any], index: Int) -> Course? {
        // Extract required fields with type safety
        guard let sourcedId = extractString(from: dict, key: "sourcedId", context: "course \(index)") else {
            return nil
        }
        
        guard let title = extractString(from: dict, key: "title", context: "course \(index)") else {
            return nil
        }
        
        guard let dateLastModified = extractString(from: dict, key: "dateLastModified", context: "course \(index)") else {
            return nil
        }
        
        guard let orgDict = dict["org"] as? [String: Any],
              let orgSourcedId = extractString(from: orgDict, key: "sourcedId", context: "course \(index) org") else {
            print("⚠️ Course \(index): Missing or invalid org structure")
            return nil
        }
        
        // Optional fields with safe extraction
        let courseCode = extractString(from: dict, key: "courseCode", context: "course \(index)", required: false)
        let grades = safelyExtractGrades(from: dict, context: "course \(index)")
        let subjects = safelyExtractSubjects(from: dict, context: "course \(index)")
        
        // Create course with validated data
        return Course(
            sourcedId: sourcedId,
            title: title,
            courseCode: courseCode,
            grades: grades,
            subjects: subjects,
            dateLastModified: dateLastModified,
            org: OrgRef(sourcedId: orgSourcedId)
        )
    }
    
    // MARK: - Safe Field Extraction
    
    /// Safely extracts a string value from a dictionary
    private static func extractString(from dict: [String: Any], key: String, context: String, required: Bool = true) -> String? {
        let value = dict[key]
        
        // Handle various data types that might be present
        if let stringValue = value as? String, !stringValue.isEmpty {
            return stringValue
        }
        
        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }
        
        if value is NSNull {
            if required {
                print("⚠️ \(context): Required field '\(key)' is null")
            }
            return nil
        }
        
        if value == nil {
            if required {
                print("⚠️ \(context): Required field '\(key)' is missing")
            }
            return nil
        }
        
        if required {
            print("⚠️ \(context): Field '\(key)' has unexpected type: \(type(of: value))")
        }
        return nil
    }
    
    /// Safely extracts and validates grades
    private static func safelyExtractGrades(from dict: [String: Any], context: String) -> [String]? {
        guard let gradesValue = dict["grades"] else {
            return nil
        }
        
        // Handle array of grades
        if let gradesArray = gradesValue as? [Any] {
            var validGrades: [String] = []
            
            for (index, grade) in gradesArray.enumerated() {
                if let validGrade = validateGrade(grade, context: "\(context) grade[\(index)]") {
                    validGrades.append(validGrade)
                }
            }
            
            return validGrades.isEmpty ? nil : validGrades
        }
        
        // Handle single grade value
        if let validGrade = validateGrade(gradesValue, context: "\(context) single grade") {
            return [validGrade]
        }
        
        print("⚠️ \(context): Unable to parse grades from value: \(gradesValue)")
        return nil
    }
    
    /// Validates and normalizes a single grade value
    private static func validateGrade(_ value: Any, context: String) -> String? {
        // Convert to string first
        var gradeString: String
        
        if let stringValue = value as? String {
            gradeString = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let numberValue = value as? NSNumber {
            gradeString = numberValue.stringValue
        } else {
            print("⚠️ \(context): Invalid grade type: \(type(of: value))")
            return nil
        }
        
        // Normalize common grade formats
        let normalizedGrade = normalizeGradeFormat(gradeString)
        
        // Validate the normalized grade
        if isValidGradeFormat(normalizedGrade) {
            return normalizedGrade
        } else {
            print("⚠️ \(context): Invalid grade format '\(gradeString)' -> '\(normalizedGrade)'")
            return nil
        }
    }
    
    /// Normalizes various grade formats to standard format
    private static func normalizeGradeFormat(_ grade: String) -> String {
        let cleaned = grade.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle empty or null strings
        if cleaned.isEmpty || cleaned == "null" || cleaned == "n/a" || cleaned == "undefined" {
            return ""
        }
        
        // Handle kindergarten variants
        if cleaned == "k" || cleaned == "kindergarten" || cleaned == "kg" {
            return "K"
        }
        
        // Handle pre-k variants
        if cleaned == "pre-k" || cleaned == "prek" || cleaned == "pre-kindergarten" {
            return "PK"
        }
        
        // Handle ordinal numbers (1st, 2nd, 3rd, etc.)
        let ordinalPattern = #"^(\d+)(?:st|nd|rd|th)$"#
        if let regex = try? NSRegularExpression(pattern: ordinalPattern),
           let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) {
            let numberRange = Range(match.range(at: 1), in: cleaned)!
            return String(cleaned[numberRange])
        }
        
        // Handle numeric grades (ensure they're in valid range)
        if let gradeNumber = Int(cleaned), gradeNumber >= 0 && gradeNumber <= 12 {
            return String(gradeNumber)
        }
        
        // Return cleaned version for other formats
        return grade.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validates if a grade format is acceptable
    private static func isValidGradeFormat(_ grade: String) -> Bool {
        // Allow empty grades (will be filtered out later)
        if grade.isEmpty {
            return false
        }
        
        // Valid single characters
        let validSingleChars = ["K", "PK"]
        if validSingleChars.contains(grade.uppercased()) {
            return true
        }
        
        // Valid numeric grades (0-12)
        if let gradeNumber = Int(grade), gradeNumber >= 0 && gradeNumber <= 12 {
            return true
        }
        
        // Allow some common descriptive grades
        let validDescriptive = ["elementary", "middle", "high", "adult"]
        if validDescriptive.contains(grade.lowercased()) {
            return true
        }
        
        // Reject obviously invalid formats
        let invalidPatterns = ["null", "undefined", "n/a", "", " "]
        return !invalidPatterns.contains(grade.lowercased())
    }
    
    /// Safely extracts subjects array
    private static func safelyExtractSubjects(from dict: [String: Any], context: String) -> [String]? {
        guard let subjectsValue = dict["subjects"] else {
            return nil
        }
        
        if let subjectsArray = subjectsValue as? [String] {
            let validSubjects = subjectsArray.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            return validSubjects.isEmpty ? nil : validSubjects
        }
        
        if let subjectString = subjectsValue as? String, !subjectString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return [subjectString]
        }
        
        print("⚠️ \(context): Unable to parse subjects from value: \(subjectsValue)")
        return nil
    }
    
    // MARK: - Date Validation
    
    /// Safely parses and validates date strings
    static func validateDateString(_ dateString: String, context: String) -> String? {
        // Common date formats to try
        let dateFormatters = [
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "dd/MM/yyyy"
        ].map { format -> DateFormatter in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            return formatter
        }
        
        // Try each formatter
        for formatter in dateFormatters {
            if let date = formatter.date(from: dateString) {
                // Convert back to ISO format
                let isoFormatter = DateFormatter()
                isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                isoFormatter.timeZone = TimeZone(abbreviation: "UTC")
                return isoFormatter.string(from: date)
            }
        }
        
        print("⚠️ \(context): Invalid date format: \(dateString)")
        return nil
    }
}

// MARK: - Enhanced Course Model with Validation

extension Course {
    
    /// Creates a course with validated data
    static func createValidated(
        sourcedId: String,
        title: String,
        courseCode: String? = nil,
        grades: [String]? = nil,
        subjects: [String]? = nil,
        dateLastModified: String,
        org: OrgRef
    ) -> Course? {
        
        // Validate required fields
        guard !sourcedId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid course: empty sourcedId")
            return nil
        }
        
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Invalid course: empty title")
            return nil
        }
        
        // Validate date
        guard let validatedDate = RobustDataParser.validateDateString(dateLastModified, context: "course \(sourcedId)") else {
            print("❌ Invalid course: bad date format")
            return nil
        }
        
        // Filter valid grades
        let validatedGrades = grades?.compactMap { grade in
            let normalized = grade.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalized.isEmpty ? nil : normalized
        }
        
        return Course(
            sourcedId: sourcedId,
            title: title,
            courseCode: courseCode?.trimmingCharacters(in: .whitespacesAndNewlines),
            grades: validatedGrades?.isEmpty == true ? nil : validatedGrades,
            subjects: subjects,
            dateLastModified: validatedDate,
            org: org
        )
    }
}