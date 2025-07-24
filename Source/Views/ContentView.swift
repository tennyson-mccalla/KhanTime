import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            Image(systemName: "book.closed.fill")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(viewModel.welcomeMessage)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
