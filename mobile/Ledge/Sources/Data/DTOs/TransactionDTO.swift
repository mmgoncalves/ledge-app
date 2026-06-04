import Foundation

struct TransactionResponse: Decodable {
    let id: String
    let description: String
    let amount: Int
    let date: String
    let type: String
    let paymentMethod: String
    let installmentIndex: Int?
    let installmentTotal: Int?

    func toDomain() -> Transaction? {
        guard
            let date = ISO8601DateFormatter.ledge.date(from: date),
            let type = TransactionType(rawValue: type),
            let paymentMethod = PaymentMethod(rawValue: paymentMethod)
        else { return nil }

        return Transaction(
            id: id,
            description: description,
            amount: amount,
            date: date,
            type: type,
            paymentMethod: paymentMethod,
            installmentIndex: installmentIndex,
            installmentTotal: installmentTotal
        )
    }
}
