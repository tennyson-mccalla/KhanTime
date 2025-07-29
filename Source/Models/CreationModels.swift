import Foundation

// These models are used for creating new content via POST requests.
// They are distinct from the Decodable models used for parsing GET responses.

// MARK: - Course Creation
struct CreateCoursePayload: Encodable {
    let course: CreateCourse
}

struct CreateCourse: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let courseCode: String
    let grades: [String]
    let subjects: [String]
    let org: OrgRef
}

// MARK: - Component Creation
struct CreateComponentPayload: Encodable {
    let courseComponent: CreateComponent
}

struct CreateComponent: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let sortOrder: Int
    let courseSourcedId: String  // Added: explicit course reference for PowerPath
    let course: ResourceRef
    let parentComponent: ResourceRef?

    // Optional fields that might help with PowerPath sync
    let prerequisites: [String]? = []
    let prerequisiteCriteria: String? = "ALL"
    let unlockDate: String? = nil
}


// MARK: - Resource Creation
struct CreateResourcePayload: Encodable {
    let resource: CreateResource
}

struct CreateResource: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let vendorResourceId: String
    let metadata: ResourceMetadataPayload
}

struct ResourceMetadataPayload: Encodable {
    let type: String
    let subType: String
    let url: String
    let format: String  // Required field that was missing
}

// MARK: - Component-Resource Association
struct CreateComponentResourcePayload: Encodable {
    let componentResource: CreateComponentResource
}

struct CreateComponentResource: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let sortOrder: Int
    let courseComponent: CourseComponentRef
    let resource: ResourceRef
}

struct CourseComponentRef: Encodable {
    let sourcedId: String
}

struct ResourceRef: Encodable {
    let sourcedId: String
}

// MARK: - User Creation
struct CreateUserPayload: Encodable {
    let user: CreateUser
}

struct CreateUser: Encodable {
    let sourcedId: String
    let status: String
    let givenName: String
    let familyName: String
    let roles: [UserRolePayload]
    let enabledUser: Bool
}

struct UserRolePayload: Encodable {
    let roleType: String
    let role: String
    let org: OrgRef
}

// MARK: - Class Creation
struct CreateClassPayload: Encodable {
    let `class`: CreateClass
}

struct CreateClass: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let classCode: String
    let classType: String
    let location: String
    let grades: [String]
    let subjects: [String]
    let course: CourseRef
    let org: OrgRef
    let terms: [TermRef]
}

struct CourseRef: Encodable {
    let sourcedId: String
    let type: String = "course"
}

struct TermRef: Encodable {
    let sourcedId: String
    let type: String = "academicSession"
}

// MARK: - Enrollment Creation
struct CreateEnrollmentPayload: Encodable {
    let enrollment: CreateEnrollment
}

struct CreateEnrollment: Encodable {
    let sourcedId: String
    let status: String
    let role: String
    let primary: Bool
    let beginDate: String
    let endDate: String
    let user: UserRef
    let `class`: ClassRef
}

// MARK: - Academic Session Creation
struct CreateAcademicSessionPayload: Encodable {
    let academicSession: CreateAcademicSession
}

struct CreateAcademicSession: Encodable {
    let sourcedId: String
    let status: String
    let title: String
    let type: String
    let startDate: String
    let endDate: String
    let schoolYear: String
    let org: OrgRef
}
