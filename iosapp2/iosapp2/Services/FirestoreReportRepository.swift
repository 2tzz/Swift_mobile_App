import Foundation
import CoreLocation

#if canImport(FirebaseFirestore)
import FirebaseFirestore
import FirebaseAuth
#endif

/// Cloud-backed repository that writes to Firestore when available,
/// and mirrors to Core Data for local cache. Falls back to Core Data
/// entirely if Firebase is not linked.
final class FirestoreReportRepository: ReportRepository {
    private let local: ReportRepository = CoreDataReportRepository()

    func save(report: Report) async throws {
        #if canImport(FirebaseFirestore)
        // Build payload
        var data: [String: Any] = [
            "issueType": report.issueType,
            "department": report.department,
            "descriptionText": report.descriptionText,
            "status": report.status.rawValue,
            "createdAt": Timestamp(date: report.createdAt)
        ]
        if let c = report.coordinate {
            data["latitude"] = c.latitude
            data["longitude"] = c.longitude
        }
        if let uid = Auth.auth().currentUser?.uid { data["userId"] = uid }

        // Save to Firestore
        let db = Firestore.firestore()
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            db.collection("reports").document(report.id.uuidString).setData(data) { error in
                if let error = error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
        // Mirror locally
        try await local.save(report: report)
        #else
        try await local.save(report: report)
        #endif
    }

    func fetchMyReports() async throws -> [Report] {
        #if canImport(FirebaseFirestore)
        guard let uid = Auth.auth().currentUser?.uid else {
            // Fallback to local if no user
            return try await local.fetchMyReports()
        }
        let db = Firestore.firestore()
        // Fetch user's reports
        let snapshot = try await db.collection("reports").whereField("userId", isEqualTo: uid).order(by: "createdAt", descending: true).getDocuments()
        let reports: [Report] = snapshot.documents.compactMap { doc in
            let d = doc.data()
            let issueType = d["issueType"] as? String ?? ""
            let department = d["department"] as? String ?? ""
            let descriptionText = d["descriptionText"] as? String ?? ""
            let statusRaw = d["status"] as? String ?? Report.Status.pending.rawValue
            let status = Report.Status(rawValue: statusRaw) ?? .pending
            let createdAt: Date
            if let ts = d["createdAt"] as? Timestamp { createdAt = ts.dateValue() } else { createdAt = Date() }
            var coord: CLLocationCoordinate2D? = nil
            if let lat = d["latitude"] as? Double, let lon = d["longitude"] as? Double {
                coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            return Report(
                id: UUID(uuidString: doc.documentID) ?? UUID(),
                createdAt: createdAt,
                issueType: issueType,
                department: department,
                descriptionText: descriptionText,
                coordinate: coord,
                status: status
            )
        }
        // Optionally mirror to local cache in background
        for r in reports { try? await local.save(report: r) }
        return reports
        #else
        return try await local.fetchMyReports()
        #endif
    }
}
