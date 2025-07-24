import Foundation

/// Service for interacting with Alpha 1EdTech GraphQL API
class GraphQLService {

    static let shared = GraphQLService()
    private let apiService: APIService

    private init(apiService: APIService = .shared) {
        self.apiService = apiService
    }

    /// GraphQL endpoint
    private var graphQLEndpoint: String {
        return APIConstants.apiBaseURL + "/graphql"
    }

    /// Execute a GraphQL query
    func query<T: Decodable>(_ query: String, variables: [String: Any]? = nil) async throws -> T {
        let body = try buildRequestBody(query: query, variables: variables)

        // Note: Alpha 1EdTech might not have a GraphQL endpoint yet
        // This is experimental - they may only support REST APIs
        print("⚠️ Attempting GraphQL query to: \(APIConstants.apiBaseURL)/graphql")
        print("Note: Alpha 1EdTech may only support REST APIs currently")

        return try await apiService.request(
            baseURL: APIConstants.apiBaseURL,
            endpoint: "/graphql",
            method: "POST",
            body: body
        )
    }

    /// Execute a GraphQL mutation
    func mutate<T: Decodable>(_ mutation: String, variables: [String: Any]? = nil) async throws -> T {
        let body = try buildRequestBody(query: mutation, variables: variables)

        return try await apiService.request(
            baseURL: APIConstants.apiBaseURL,
            endpoint: "/graphql",
            method: "POST",
            body: body
        )
    }

    /// Build request body for GraphQL
    private func buildRequestBody(query: String, variables: [String: Any]?) throws -> Data {
        var payload: [String: Any] = ["query": query]

        if let variables = variables {
            payload["variables"] = variables
        }

        return try JSONSerialization.data(withJSONObject: payload)
    }
}

// MARK: - Common GraphQL Queries

extension GraphQLService {

    /// Fetch courses using GraphQL
    func fetchCoursesGraphQL() async throws -> GraphQLCoursesResponse {
        let query = """
        query GetCourses($limit: Int, $offset: Int) {
            courses(limit: $limit, offset: $offset) {
                edges {
                    node {
                        sourcedId
                        status
                        title
                        courseCode
                        grades
                        subjects
                        org {
                            sourcedId
                            name
                        }
                        createdDate
                        modifiedDate
                    }
                }
                pageInfo {
                    hasNextPage
                    endCursor
                }
            }
        }
        """

        let variables: [String: Any] = [
            "limit": 50,
            "offset": 0
        ]

        return try await self.query(query, variables: variables)
    }

    /// Fetch course details with components
    func fetchCourseDetails(courseId: String) async throws -> GraphQLCourseDetailResponse {
        let query = """
        query GetCourseDetails($courseId: String!) {
            course(sourcedId: $courseId) {
                sourcedId
                title
                courseCode
                grades
                subjects
                components {
                    edges {
                        node {
                            sourcedId
                            title
                            sortOrder
                            resources {
                                edges {
                                    node {
                                        sourcedId
                                        title
                                        type
                                        metadata
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        let variables: [String: Any] = ["courseId": courseId]

        return try await self.query(query, variables: variables)
    }

    /// Fetch QTI assessments
    func fetchQTIAssessments() async throws -> GraphQLQTIResponse {
        let query = """
        query GetQTIAssessments($type: String!) {
            resources(type: $type) {
                edges {
                    node {
                        sourcedId
                        title
                        vendorResourceId
                        metadata {
                            type
                            subType
                            url
                        }
                    }
                }
            }
        }
        """

        let variables: [String: Any] = ["type": "qti"]

        return try await self.query(query, variables: variables)
    }
}

// MARK: - GraphQL Response Models

struct GraphQLCoursesResponse: Decodable {
    let data: CoursesData

    struct CoursesData: Decodable {
        let courses: CourseConnection
    }

    struct CourseConnection: Decodable {
        let edges: [CourseEdge]
        let pageInfo: PageInfo
    }

    struct CourseEdge: Decodable {
        let node: GraphQLCourse
    }
}

struct GraphQLCourse: Decodable {
    let sourcedId: String
    let status: String
    let title: String
    let courseCode: String?
    let grades: [String]?
    let subjects: [String]?
    let org: GraphQLOrg?
    let createdDate: String?
    let modifiedDate: String?
}

struct GraphQLOrg: Decodable {
    let sourcedId: String
    let name: String?
}

struct PageInfo: Decodable {
    let hasNextPage: Bool
    let endCursor: String?
}

struct GraphQLCourseDetailResponse: Decodable {
    let data: CourseDetailData

    struct CourseDetailData: Decodable {
        let course: CourseDetail
    }

    struct CourseDetail: Decodable {
        let sourcedId: String
        let title: String
        let courseCode: String?
        let grades: [String]?
        let subjects: [String]?
        let components: ComponentConnection?
    }

    struct ComponentConnection: Decodable {
        let edges: [ComponentEdge]
    }

    struct ComponentEdge: Decodable {
        let node: GraphQLComponent
    }
}

struct GraphQLComponent: Decodable {
    let sourcedId: String
    let title: String
    let sortOrder: Int?
    let resources: ResourceConnection?
}

struct ResourceConnection: Decodable {
    let edges: [ResourceEdge]
}

struct ResourceEdge: Decodable {
    let node: GraphQLResource
}

struct GraphQLResource: Decodable {
    let sourcedId: String
    let title: String
    let type: String?
    let vendorResourceId: String?
    let metadata: ResourceMetadata?
}

struct GraphQLQTIResponse: Decodable {
    let data: QTIData

    struct QTIData: Decodable {
        let resources: ResourceConnection
    }
}

// MARK: - GraphQL Error Handling

struct GraphQLError: Error, Decodable {
    let message: String
    let extensions: [String: AnyCodable]?
}

struct GraphQLErrorResponse: Decodable {
    let errors: [GraphQLError]?
}

// Helper for decoding arbitrary JSON values
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else {
            value = NSNull()
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let string = value as? String {
            try container.encode(string)
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else {
            try container.encodeNil()
        }
    }
}
