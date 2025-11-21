import SwiftUI
import MapKit
import PhotosUI

struct SubmissionView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: SubmissionViewModel
    @State private var showCamera: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil

    init(coordinate: CLLocationCoordinate2D?) {
        _viewModel = StateObject(wrappedValue: SubmissionViewModel(classifier: .shared, initialCoordinate: coordinate))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Image") {
                    if let image = viewModel.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label(viewModel.capturedImage == nil ? "Capture Photo" : "Capture New Photo", systemImage: "camera.viewfinder")
                    }

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label(viewModel.capturedImage == nil ? "Upload from Photos" : "Upload Different Photo", systemImage: "photo.on.rectangle")
                    }
                }

                Section("Details") {
                    TextField("Issue Type", text: $viewModel.issueType)
                    TextField("Responsible Department", text: $viewModel.department)
                    TextField("Description", text: $viewModel.descriptionText, axis: .vertical)
                }

                if let coordinate = viewModel.coordinate {
                    Section("Location") {
                        Text("Latitude: \(coordinate.latitude)")
                        Text("Longitude: \(coordinate.longitude)")
                    }
                }

                Section {
                    Button {
                        Task {
                            do {
                                try await viewModel.submitReport()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    } label: {
                        Text("Submit Report")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.capturedImage == nil)
                }
            }
            .navigationTitle("New Road Issue")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    Task { @MainActor in
                        viewModel.assignCapturedImage(image)
                        await viewModel.classifyCurrentImage()
                    }
                }
            }
            .alert("Submission failed", isPresented: $showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(errorMessage)
            })
            .onChange(of: selectedItem) { newItem in
                guard let newItem = newItem else { return }
                Task { @MainActor in
                    do {
                        if let data = try await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            viewModel.assignCapturedImage(image)
                            await viewModel.classifyCurrentImage()
                        }
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}
