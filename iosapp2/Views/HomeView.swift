import SwiftUI
import MapKit
import CoreLocation
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showSubmission: Bool = false

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .ignoresSafeArea()

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CivicFix")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text("Tap Scan Road to report an issue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                HStack {
                    Spacer()

                    Button(action: {
                        showSubmission = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Scan Road")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(.ultraThickMaterial)
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            locationManager.requestAuthorization()
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { location in
            viewModel.updateRegion(with: location)
        }
        .sheet(isPresented: $showSubmission) {
            SubmissionView(coordinate: viewModel.region.center)
        }
    }
}

#Preview {
    HomeView()
}
