import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthService

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.95), Color.black.opacity(0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 20) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.yellow)
                    .shadow(color: Color.yellow.opacity(0.5), radius: 12, x: 0, y: 0)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create Account")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Join FixLK to improve urban road safety")
                        .foregroundColor(Color.yellow.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    TextField("Full name", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.35)))

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.35)))

                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.yellow.opacity(0.35)))
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
                        ProgressView()
                            .tint(Color.yellow)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Create Account").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.yellow)
                .foregroundColor(.black)
                .disabled(name.isEmpty || email.isEmpty || password.isEmpty)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.yellow.opacity(0.4), lineWidth: 1.2)
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
