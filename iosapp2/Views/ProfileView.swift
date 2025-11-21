import SwiftUI
import Charts

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        List {
            if let user = auth.currentUser {
                Section("Account") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(user.name).font(.headline)
                            Text(user.email).foregroundColor(.secondary).font(.subheadline)
                        }
                    }

                    Button(role: .destructive) { auth.signOut() } label: {
                        Text("Sign Out").frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            Section("Overview") {
                if viewModel.myReports.isEmpty {
                    Text("No reports submitted yet.")
                        .foregroundColor(.secondary)
                } else {
                    Text("Total reports: \(viewModel.myReports.count)")
                }

                if !viewModel.issueTypeStats.isEmpty {
                    Chart(viewModel.issueTypeStats) { stat in
                        BarMark(
                            x: .value("Count", stat.count),
                            y: .value("Type", stat.issueType)
                        )
                    }
                    .frame(height: 200)
                }
            }

            Section("My Reports") {
                if viewModel.myReports.isEmpty {
                    Text("Reports you submit will appear here.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.myReports) { report in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.issueType)
                                .font(.headline)

                            Text(report.department)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(report.descriptionText)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(2)

                            Text(report.createdAt, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .task {
            await viewModel.loadReports()
        }
    }
}
