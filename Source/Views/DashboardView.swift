import SwiftUI

struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Loading Courses...")
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            viewModel.loadCourses()
                        }
                        .padding()
                    }
                } else {
                    List {
                        ForEach(viewModel.courses) { course in
                            NavigationLink(destination: SyllabusView(course: course)) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(course.title)
                                        .font(.headline)
                                    if let courseCode = course.courseCode {
                                        Text("Course Code: \(courseCode)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    if let grades = course.grades, !grades.isEmpty {
                                        Text("Grades: \(grades.joined(separator: ", "))")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .refreshable {
                        viewModel.loadCourses()
                    }
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        viewModel.createTestCourse()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $viewModel.sortOption) {
                            ForEach(SortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
            }
            .onAppear {
                // Load courses when the view first appears
                if viewModel.courses.isEmpty {
                    viewModel.loadCourses()
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
