import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError = false
    var onLogin: () -> Void
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(Theme.headerGradient)
                .blur(radius: 120)
                .opacity(0.35)
                .frame(width: 360, height: 360)
                .offset(x: -120, y: -320)

            VStack {
                Spacer(minLength: 40)

                // Brand/title area
                VStack(spacing: 8) {
                    Image(systemName: "cube.transparent")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .foregroundStyle(.white.opacity(0.9))
                        .shadow(radius: 16)

                    Text("TrackSpace")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Smart inventory, powered by vision")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }
                .padding(.bottom, 28)

                // Glass card containing the form
                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Sign In")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.textPrimary)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            Text("Password")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)

                            SecureField("Password", text: $password)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        if showError {
                            Text("Invalid credentials")
                                .font(.caption)
                                .foregroundColor(.red)
                                .transition(.opacity)
                        }

                        PrimaryButton(action: attempt) {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                        }

                        Button(action: { dismissKeyboard(); showRegister = true }) {
                            Text("Don't have an account? Register")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.9))
                                .underline()
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Subtle footer hint
                Text("Secure sign-in • Your data stays on device")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 16)
            }
        }
        .sheet(isPresented: $showRegister) {
            RegistrationView {
                // after successful register, call onLogin to switch to app
                onLogin()
            }
        }
    }

    private func attempt() {
        let ok = UserAccountStore.signIn(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        if ok { onLogin() } else { showError = true }
    }
}
