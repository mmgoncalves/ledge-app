import Foundation

// MARK: - Current Cycle Response

struct BillingCycleResponse: Decodable {
    let id: String
    let startDate: String
    let endDate: String
    let cutDay: Int

    func toDomain() -> BillingCycle? {
        guard
            let start = ISO8601DateFormatter.ledge.date(from: startDate),
            let end = ISO8601DateFormatter.ledge.date(from: endDate)
        else { return nil }
        return BillingCycle(id: id, startDate: start, endDate: end, cutDay: cutDay)
    }
}

// MARK: - Cycle Summary Response

struct CycleSummaryResponse: Decodable {
    let totalIncome: Int
    let totalEssential: Int
    let totalNonEssential: Int
    let balance: Int
    let transactionCount: Int

    func toDomain() -> CycleSummary {
        CycleSummary(
            totalIncome: totalIncome,
            totalEssential: totalEssential,
            totalNonEssential: totalNonEssential,
            balance: balance,
            transactionCount: transactionCount
        )
    }
}

// MARK: - Cycle Neighbors Response

struct CycleNeighborsResponse: Decodable {
    let previous: BillingCycleResponse?
    let next: BillingCycleResponse?

    func toDomain() -> CycleNeighbors {
        CycleNeighbors(
            previous: previous?.toDomain(),
            next: next?.toDomain()
        )
    }
}

// MARK: - Date helpers

extension ISO8601DateFormatter {
    static let ledge: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
