import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            LiquidBackground().allowsHitTesting(false)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Account")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Join FixLK to report and track issues")
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    TextField("Full name", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25)))

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25)))

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.25)))
                }

                if let error = auth.authError {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await auth.signUp(name: name, email: email, password: password) }
                } label: {
                    if auth.isAuthenticating {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.white.opacity(0.85))
                .foregroundColor(.black)
                .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1.2)
            )
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    RegisterView().environmentObject(AuthService())
}
