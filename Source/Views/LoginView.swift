import SwiftUI

struct LoginView: View {
    
    @StateObject private var viewModel = LoginViewModel()
    @State private var navigateToMainApp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("KhanTime")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    viewModel.login()
                }) {
                    Text("Connect to TimeBack")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            Text("Note: Ensure you have replaced the placeholder credentials in `Utilities/Credentials.swift`.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onChange(of: viewModel.isAuthenticated) {
            // This is the modern syntax for onChange as of iOS 17.
            // The closure is called when the value changes.
            if viewModel.isAuthenticated {
                navigateToMainApp = true
            }
        }
        .fullScreenCover(isPresented: $navigateToMainApp) {
            // Present the DashboardView after a successful login.
            DashboardView()
        }
    }
}

#Preview {
    LoginView()
}
