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
        Form {
            Section(header: Text("Profile")) {
                HStack {
                    if let ui = image ?? loadImageFromStore() {
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
                        TextField("Phone", text: $phone)
                            .keyboardType(.phonePad)
                    }
                }
                Button("Change Photo") {
                    // hide keyboard before presenting the photo picker to avoid layout conflicts
                    dismissKeyboard()
                    isPicking = true
                }
            }

            Section {
                Button("Save") { save() }
                    .appPrimaryButtonStyle()
                Button("Sign Out") { UserAccountStore.signOut(); NotificationCenter.default.post(name: Notification.Name("UserSignedOut"), object: nil) }
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Account")
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
