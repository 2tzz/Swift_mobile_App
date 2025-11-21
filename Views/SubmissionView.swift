import SwiftUI
import MapKit

struct SubmissionView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: SubmissionViewModel
    @State private var showCamera: Bool = false

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
                    } else {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Capture Road Photo", systemImage: "camera.viewfinder")
                        }
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
                                // In a later phase, surface a user-facing error.
                                dismiss()
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
        }
    }
}
