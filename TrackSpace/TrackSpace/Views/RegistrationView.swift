import SwiftUI
import PhotosUI

struct RegistrationView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var phone: String = ""
    @State private var image: UIImage? = nil
    @State private var isPicking = false
    @State private var showError = false

    var onRegister: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(spacing: 16) {
                                avatar

                                modernField("Full name", text: $name, keyboard: .default, autocapitalization: .words)
                                modernField("Email", text: $email, keyboard: .emailAddress, autocapitalization: .never)
                                SecureField("Password", text: $password)
                                    .padding(12)
                                    .background(Color.white.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                modernField("Phone", text: $phone, keyboard: .phonePad, autocapitalization: .never)

                                Button {
                                    dismissKeyboard()
                                    isPicking = true
                                } label: {
                                    Label("Choose Photo", systemImage: "camera.fill")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                .tint(Theme.primaryStart)
                            }
                        }

                        GlassCard {
                            VStack(spacing: 12) {
                                PrimaryButton(action: attemptRegister) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                        Text("Create Account")
                                    }
                                }
                                if showError {
                                    Text("Please fill all required fields.")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 28)
                }
            }
            .navigationTitle("Register")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .sheet(isPresented: $isPicking) {
                ImagePicker { img in
                    if let i = img { image = i }
                    isPicking = false
                }
            }
        }
    }

    private func attemptRegister() {
        // basic validation
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.isEmpty else { showError = true; return }

        var imagePath: String? = nil
        if let ui = image, let url = try? ImageStore.save(ui, name: "user_profile_\(UUID().uuidString)") {
            imagePath = url.path
            NotificationCenter.default.post(name: .imageSaved, object: nil, userInfo: ["path": url.path, "context": "registration"])
        }

        let ok = UserAccountStore.register(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password, name: name, phone: phone, imagePath: imagePath)
        if ok { onRegister() } else { showError = true }
    }
}

// MARK: - Private helpers
extension RegistrationView {
    private var avatar: some View {
        Group {
            if let ui = image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 96, height: 96)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func modernField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default, autocapitalization: TextInputAutocapitalization = .never) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(placeholder)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocapitalization)
                .padding(12)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// Simple picker reuse
private struct ImagePicker: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images
        cfg.selectionLimit = 1
        let pc = PHPickerViewController(configuration: cfg)
        pc.delegate = context.coordinator
        return pc
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let first = results.first else { completion(nil); return }
            if first.itemProvider.canLoadObject(ofClass: UIImage.self) {
                first.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in DispatchQueue.main.async { self.completion(obj as? UIImage) } }
            } else { completion(nil) }
        }
    }
}
