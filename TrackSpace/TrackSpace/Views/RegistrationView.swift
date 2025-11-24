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
            Form {
                Section(header: Text("Profile")) {
                    HStack {
                        if let ui = image {
                            Image(uiImage: ui)
                                .resizable()
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .frame(width: 72, height: 72)
                                .foregroundStyle(.secondary)
                        }
                        VStack(alignment: .leading) {
                            TextField("Full name", text: $name)
                            TextField("Email", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                            SecureField("Password", text: $password)
                        }
                    }
                    Button("Choose Photo") {
                        // dismiss keyboard to avoid accessory/input layout conflicts
                        dismissKeyboard()
                        isPicking = true
                    }
                }

                Section {
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                }

                Section {
                    Button("Register") { attemptRegister() }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                        .background(LinearGradient(gradient: Gradient(colors: [Theme.primaryStart, Theme.primaryEnd]), startPoint: .leading, endPoint: .trailing))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Theme.primaryStart.opacity(0.3), radius: 8, x: 0, y: 6)
                    if showError { Text("Registration failed - please fill required fields").foregroundColor(.red).font(.caption) }
                }
            }
            .navigationTitle("Register")
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
