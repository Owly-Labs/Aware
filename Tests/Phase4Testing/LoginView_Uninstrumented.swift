import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button(isLoading ? "Signing In..." : "Sign In") {
                login()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            HStack {
                Button("Forgot Password?") {
                    // Handle forgot password
                }

                Spacer()

                Button("Create Account") {
                    // Handle signup
                }
            }
            .font(.caption)
        }
        .padding()
    }

    func login() {
        guard !email.isEmpty, !password.isEmpty else {
            showError = true
            errorMessage = "Please enter both email and password"
            return
        }

        isLoading = true
        showError = false

        // Login API call would go here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
        }
    }
}
