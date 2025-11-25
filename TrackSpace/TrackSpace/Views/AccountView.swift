import SwiftUI
import PhotosUI
import UIKit

struct AccountView: View {
    @State private var name: String = UserAccountStore.current?.name ?? ""
    @State private var email: String = UserAccountStore.current?.email ?? ""
    @State private var phone: String = UserAccountStore.current?.phone ?? ""
    @State private var isPicking = false
    @State private var image: UIImage? = nil
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .center, spacing: 18) {
                                avatar
                                VStack(alignment: .leading, spacing: 12) {
                                    modernField("Full name", text: $name, keyboard: .default, autocapitalization: .words)
                                    modernField("Email", text: $email, keyboard: .emailAddress, autocapitalization: .never)
                                    modernField("Phone", text: $phone, keyboard: .phonePad, autocapitalization: .never)
                                }
                            }
                            Button {
                                dismissKeyboard()
                                isPicking = true
                            } label: {
                                Label("Change Photo", systemImage: "camera.fill")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.bordered)
                            .tint(Theme.primaryStart)
                            .controlSize(.small)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Actions")
                                .font(.headline)
                                .foregroundStyle(Theme.textPrimary)

                            PrimaryButton(action: save) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Save Profile")
                                }
                            }

                            Button {
                                UserAccountStore.signOut()
                                NotificationCenter.default.post(name: Notification.Name("UserSignedOut"), object: nil)
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Sign Out")
                                        .font(.headline)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 30)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .sheet(isPresented: $isPicking) {
            ImagePicker { img in
                if let i = img { image = i }
                isPicking = false
            }
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(title: Text("Save"), message: Text(saveAlertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func save() {
        var acct = UserAccountStore.current ?? UserAccount(name: "", email: email, phone: phone, imagePath: nil)
        acct.name = name
        acct.email = email
        acct.phone = phone
        do {
            if let ui = image {
                let url = try ImageStore.save(ui, name: "user_profile")
                acct.imagePath = url.path
                NotificationCenter.default.post(name: .imageSaved, object: nil, userInfo: ["path": url.path, "context": "profile"])
            }
            UserAccountStore.current = acct
            // sync local state so UI reflects saved values immediately
            name = acct.name
            email = acct.email
            phone = acct.phone ?? ""
            image = loadImageFromStore()
            saveAlertMessage = "Profile saved"
            showSaveAlert = true
        } catch {
            print("AccountView: save error: \(error)")
            saveAlertMessage = "Save failed: \(error.localizedDescription)"
            showSaveAlert = true
        }
    }

    private func loadImageFromStore() -> UIImage? {
        if let path = UserAccountStore.current?.imagePath {
            let url = URL(fileURLWithPath: path)
            if let d = try? Data(contentsOf: url), let ui = UIImage(data: d) { return ui }
        }
        return nil
    }

    private var avatar: some View {
        Group {
            if let ui = image ?? loadImageFromStore() {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 88, height: 88)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Theme.shadow.opacity(0.4), radius: 12, x: 0, y: 8)
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

// Reuse image picker from earlier file if available
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
