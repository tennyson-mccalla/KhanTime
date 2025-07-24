import SwiftUI

/// View for exploring and testing Alpha 1EdTech APIs
struct APIExplorerView: View {
    @StateObject private var viewModel = APIExplorerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            // Header
            Text("API Explorer")
                .font(.largeTitle)
                .bold()
                .padding()

            // Tab Selection
            Picker("API Type", selection: $selectedTab) {
                Text("REST").tag(0)
                Text("GraphQL").tag(1)
                Text("QTI").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            // Content based on tab
            ScrollView {
                switch selectedTab {
                case 0:
                    RESTExplorerView(viewModel: viewModel)
                case 1:
                    GraphQLExplorerView(viewModel: viewModel)
                case 2:
                    QTIExplorerView(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }

            // Results section
            if !viewModel.results.isEmpty {
                VStack(alignment: .leading) {
                    Text("Results:")
                        .font(.headline)

                    ScrollView {
                        Text(viewModel.results)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }

            // Error display
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onAppear {
            viewModel.authenticate()
        }
    }
}

// MARK: - REST Explorer
struct RESTExplorerView: View {
    @ObservedObject var viewModel: APIExplorerViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("OneRoster REST API")
                .font(.title2)
                .bold()

            Button("Fetch All Courses") {
                viewModel.fetchCoursesREST()
            }
            .buttonStyle(.borderedProminent)

            Button("Fetch First Course Details") {
                viewModel.fetchFirstCourseDetails()
            }
            .buttonStyle(.bordered)

            Button("Fetch QTI Resources") {
                viewModel.fetchQTIResources()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - GraphQL Explorer
struct GraphQLExplorerView: View {
    @ObservedObject var viewModel: APIExplorerViewModel

    var body: some View {
        VStack(spacing: 20) {
                        Text("GraphQL API")
                .font(.title2)
                .bold()

            Text("Endpoint: \(APIConstants.scalarEndpoint)")
                .font(.caption)
                .foregroundColor(.gray)

            Text("⚠️ Note: Alpha 1EdTech may only support REST APIs currently")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal)

            Button("Fetch Courses (GraphQL)") {
                viewModel.fetchCoursesGraphQL()
            }
            .buttonStyle(.borderedProminent)

            Button("Fetch Course with Components") {
                viewModel.fetchCourseWithComponents()
            }
            .buttonStyle(.bordered)

            Button("Fetch QTI Assessments") {
                viewModel.fetchQTIAssessmentsGraphQL()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

// MARK: - QTI Explorer
struct QTIExplorerView: View {
    @ObservedObject var viewModel: APIExplorerViewModel
    @State private var selectedQTI: QTIItem?

    var body: some View {
        VStack(spacing: 20) {
            Text("QTI Assessment API")
                .font(.title2)
                .bold()

            Text("QTI Endpoint: https://qti.alpha-1edtech.com/scalar")
                .font(.caption)
                .foregroundColor(.gray)

            Button("List QTI Assessments") {
                viewModel.listQTIAssessments()
            }
            .buttonStyle(.borderedProminent)

            if !viewModel.qtiItems.isEmpty {
                Text("Available QTI Items:")
                    .font(.headline)

                ForEach(viewModel.qtiItems) { item in
                    Button(action: {
                        selectedQTI = item
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                Text(item.url)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .sheet(item: $selectedQTI) { item in
            QTIView(resource: ComponentResource(
                sourcedId: item.id,
                title: item.title,
                sortOrder: 1,
                resource: Resource(
                    sourcedId: item.id,
                    status: "active",
                    title: item.title,
                    vendorResourceId: nil,
                    metadata: ResourceMetadata(
                        type: "qti",
                        subType: "qti-test",
                        url: item.url
                    )
                )
            ))
        }
    }
}

// MARK: - View Model
@MainActor
class APIExplorerViewModel: ObservableObject {
    @Published var results = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var qtiItems: [QTIItem] = []

    private let courseService = CourseService()
    private let graphQLService = GraphQLService.shared
    private let contentProvider = TimeBackContentProvider()

    func authenticate() {
        Task {
            do {
                _ = try await AuthService.shared.getValidAccessToken()
                results = "✅ Authentication successful"
            } catch {
                errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - REST API Tests

    func fetchCoursesREST() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let courses = try await courseService.fetchAllCourses()
                results = "Found \(courses.count) courses:\n\n"
                for (index, course) in courses.prefix(5).enumerated() {
                    results += "\(index + 1). \(course.title)\n"
                    results += "   ID: \(course.sourcedId)\n"
                    results += "   Grades: \(course.grades?.joined(separator: ", ") ?? "N/A")\n\n"
                }

                if courses.count > 5 {
                    results += "... and \(courses.count - 5) more"
                }
            } catch {
                errorMessage = "Failed to fetch courses: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func fetchFirstCourseDetails() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let courses = try await courseService.fetchAllCourses()
                guard let firstCourse = courses.first else {
                    errorMessage = "No courses found"
                    return
                }

                let syllabus = try await courseService.fetchSyllabus(for: firstCourse.sourcedId)

                results = "Course: \(syllabus.courseTitle)\n\n"
                results += "Components:\n"

                if let components = syllabus.components {
                    for component in components {
                        results += "- \(component.title)\n"
                        if let resources = component.resources {
                            for resource in resources {
                                results += "  • \(resource.title) (\(resource.resource.metadata?.type ?? "unknown"))\n"
                            }
                        }
                    }
                } else {
                    results += "No components found"
                }
            } catch {
                errorMessage = "Failed to fetch course details: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func fetchQTIResources() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let courses = try await courseService.fetchAllCourses()
                var qtiCount = 0

                results = "Searching for QTI resources...\n\n"

                for course in courses.prefix(10) {
                    if let syllabus = try? await courseService.fetchSyllabus(for: course.sourcedId),
                       let components = syllabus.components {
                        for component in components {
                            if let resources = component.resources {
                                for resource in resources {
                                    if resource.resource.metadata?.type == "qti" {
                                        qtiCount += 1
                                        results += "Found QTI: \(resource.title)\n"
                                        results += "  URL: \(resource.resource.metadata?.url ?? "N/A")\n\n"

                                        // Add to QTI items
                                        if let url = resource.resource.metadata?.url {
                                            qtiItems.append(QTIItem(
                                                id: resource.resource.sourcedId,
                                                title: resource.title,
                                                url: url
                                            ))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                results += "\nTotal QTI resources found: \(qtiCount)"
            } catch {
                errorMessage = "Failed to fetch QTI resources: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    // MARK: - GraphQL Tests

    func fetchCoursesGraphQL() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let response = try await graphQLService.fetchCoursesGraphQL()
                let courses = response.data.courses.edges

                results = "GraphQL: Found \(courses.count) courses\n\n"
                for (index, edge) in courses.prefix(5).enumerated() {
                    let course = edge.node
                    results += "\(index + 1). \(course.title)\n"
                    results += "   Code: \(course.courseCode ?? "N/A")\n"
                    results += "   Org: \(course.org?.name ?? "N/A")\n\n"
                }
            } catch {
                errorMessage = "GraphQL error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func fetchCourseWithComponents() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                // First get a course ID
                let courses = try await courseService.fetchAllCourses()
                guard let firstCourse = courses.first else {
                    errorMessage = "No courses found"
                    return
                }

                let response = try await graphQLService.fetchCourseDetails(courseId: firstCourse.sourcedId)
                let course = response.data.course

                results = "GraphQL Course Details:\n\n"
                results += "Title: \(course.title)\n"
                results += "Code: \(course.courseCode ?? "N/A")\n\n"

                if let components = course.components?.edges {
                    results += "Components (\(components.count)):\n"
                    for component in components {
                        results += "- \(component.node.title)\n"
                        if let resources = component.node.resources?.edges {
                            for resource in resources {
                                results += "  • \(resource.node.title) (\(resource.node.type ?? "unknown"))\n"
                            }
                        }
                    }
                }
            } catch {
                errorMessage = "GraphQL error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func fetchQTIAssessmentsGraphQL() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let response = try await graphQLService.fetchQTIAssessments()
                let resources = response.data.resources.edges

                results = "GraphQL QTI Assessments:\n\n"
                for edge in resources {
                    let resource = edge.node
                    results += "- \(resource.title)\n"
                    results += "  URL: \(resource.metadata?.url ?? "N/A")\n"
                    results += "  Vendor ID: \(resource.vendorResourceId ?? "N/A")\n\n"
                }

                results += "Total: \(resources.count) QTI assessments"
            } catch {
                errorMessage = "GraphQL error: \(error.localizedDescription)"
            }

            isLoading = false
        }
    }

    func listQTIAssessments() {
        // This combines both REST and GraphQL to find QTI items
        fetchQTIResources()
    }
}

// MARK: - Models
struct QTIItem: Identifiable {
    let id: String
    let title: String
    let url: String
}
