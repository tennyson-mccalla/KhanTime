import SwiftUI

struct SyllabusView: View {

    @StateObject private var viewModel: SyllabusViewModel

    // The course is passed in to initialize the ViewModel
    init(course: Course) {
        _viewModel = StateObject(wrappedValue: SyllabusViewModel(course: course))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Syllabus...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        viewModel.loadSyllabus()
                    }
                }
            } else if let syllabus = viewModel.syllabus {
                if let components = syllabus.components, !components.isEmpty {
                    List {
                        ForEach(components) { component in
                            SyllabusComponentView(component: component)
                        }
                    }
                } else {
                    Text("This course doesn't have any content yet.")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
        .navigationTitle(viewModel.course.title)
        .onAppear {
            // Load the syllabus when the view first appears
            if viewModel.syllabus == nil {
                viewModel.loadSyllabus()
            }
        }
    }
}

// A view to represent a single component (e.g., a Unit), which can contain
// other components and resources. It's a collapsible section.
struct SyllabusComponentView: View {
    let component: CourseComponent

    var body: some View {
        DisclosureGroup {
            // Display sub-components recursively by calling this same view
            if let subComponents = component.subComponents {
                ForEach(subComponents) { subComponent in
                    SyllabusComponentView(component: subComponent)
                        .padding(.leading)
                }
            }

            // Display the resources within this component
            if let resources = component.componentResources {
                ForEach(resources) { resource in
                    SyllabusResourceView(resource: resource)
                        .padding(.leading)
                }
            }
        } label: {
            Text(component.title)
                .font(.headline)
        }
    }
}

// A view to represent a single, tappable resource (e.g., a video or quiz)
struct SyllabusResourceView: View {
    let resource: ComponentResource

    var body: some View {
        // Check if the resource is a QTI item to make it navigable.
        if resource.resource.metadata?.type == "qti" {
            NavigationLink(destination: QTIView(resource: resource)) {
                resourceContent
            }
        } else {
            // For non-QTI items, just display the content without navigation for now.
            resourceContent
        }
    }

    // The actual content of the resource row (icon and title).
    private var resourceContent: some View {
        HStack {
            Image(systemName: icon(for: resource.resource.metadata?.type))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(resource.title)
            Spacer()
        }
        .padding(.vertical, 4)
    }

    // Helper function to return a relevant SF Symbol icon based on the resource type
    private func icon(for type: String?) -> String {
        switch type {
        case "qti":
            return "pencil.and.scribble"
        case "video":
            return "video.fill"
        case "text":
            return "doc.text.fill"
        default:
            return "book.closed.fill"
        }
    }
}
