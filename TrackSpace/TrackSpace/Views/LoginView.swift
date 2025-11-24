import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError = false
    var onLogin: () -> Void
    @State private var showRegister = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(Color.accentColor)
                Text("Welcome to TrackSpace").font(.title2).bold()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email").font(.caption)
                    TextField("you@example.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Text("Password").font(.caption)
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                Button(action: attempt) {
                    Text("Sign in")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: { dismissKeyboard(); showRegister = true }) {
                    Text("Don't have an account? Register")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showRegister) {
                    RegistrationView {
                        // after successful register, call onLogin to switch to app
                        onLogin()
                    }
                }
                if showError { Text("Invalid credentials").foregroundColor(.red).font(.caption) }
                Spacer()
            }
            .padding()
            .navigationTitle("Sign In")
        }
    }

    private func attempt() {
        let ok = UserAccountStore.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        if ok { onLogin() } else { showError = true }
    }
}
