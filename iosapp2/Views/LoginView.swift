import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            LiquidBackground()
                .allowsHitTesting(false)

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to CivicFix")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Sign in to continue")
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }

                if let error = auth.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await auth.signIn(email: email, password: password) }
                } label: {
                    if auth.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.85))
                .foregroundColor(.black)
                .disabled(email.isEmpty || password.isEmpty)

                HStack(spacing: 6) {
                    Text("No account?")
                        .foregroundColor(.white.opacity(0.8))
                    NavigationLink("Create one", destination: RegisterView().environmentObject(auth))
                        .fontWeight(.semibold)
                }
            }
            .padding(24)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .blendMode(.softLight)
                        .opacity(0.7)
                }
                .allowsHitTesting(false)
            )
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            .padding()
        }
    }
}

#Preview {
    LoginView().environmentObject(AuthService())
}
