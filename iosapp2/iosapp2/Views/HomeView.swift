import SwiftUI
import MapKit
import CoreLocation
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var showSubmission: Bool = false
    @State private var showProfile: Bool = false

    var body: some View {
        ZStack {
            Map(
                coordinateRegion: $viewModel.region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FixLK")
                            .font(.title2.bold())
                        Text("Report road issues around you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22, weight: .semibold))
                    }
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 6)
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                VStack(spacing: 12) {
                    Button(action: { showSubmission = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Report Road Issue")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.ultraThickMaterial)
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 22)
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
        .sheet(isPresented: $showProfile) {
            NavigationStack { ProfileView() }
                .environmentObject(AuthService())
        }
    }
}

#Preview {
    HomeView()
}
