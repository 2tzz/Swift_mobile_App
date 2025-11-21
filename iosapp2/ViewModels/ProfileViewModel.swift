import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var myReports: [Report] = []

    private let repository: ReportRepository

    init(repository: ReportRepository = CoreDataReportRepository()) {
        self.repository = repository
    }

    func loadReports() async {
        do {
            let reports = try await repository.fetchMyReports()
            myReports = reports
        } catch {
            // In a later phase, we can surface an error to the user.
            myReports = []
        }
    }

    struct IssueTypeStat: Identifiable {
        let id = UUID()
        let issueType: String
        let count: Int
    }

    var issueTypeStats: [IssueTypeStat] {
        let groups = Dictionary(grouping: myReports) { $0.issueType.isEmpty ? "Other" : $0.issueType }
        return groups.map { key, value in
            IssueTypeStat(issueType: key, count: value.count)
        }
        .sorted { $0.count > $1.count }
    }
}
