import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

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

            VStack(spacing: 24) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(Color.yellow)
                    .shadow(color: Color.yellow.opacity(0.5), radius: 12, x: 0, y: 0)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to FixLK")
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
                                .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
                        )

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.yellow.opacity(0.35), lineWidth: 1)
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
                            .tint(Color.yellow)
                            .progressViewStyle(.circular)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.yellow)
                .foregroundColor(.black)
                .disabled(email.isEmpty || password.isEmpty)

                HStack(spacing: 6) {
                    Text("No account?")
                        .foregroundColor(.white.opacity(0.8))
                    NavigationLink("Create one", destination: RegisterView().environmentObject(auth))
                        .foregroundColor(Color.yellow)
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
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1.2)
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(colors: [Color.yellow.opacity(0.12), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
