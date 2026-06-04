import Foundation

struct BillingCycle: Identifiable, Equatable {
    let id: String
    let startDate: Date
    let endDate: Date
    let cutDay: Int
}
