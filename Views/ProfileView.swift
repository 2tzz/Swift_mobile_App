import SwiftUI
import Charts

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        List {
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
