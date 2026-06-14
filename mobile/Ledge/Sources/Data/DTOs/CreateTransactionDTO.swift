import Foundation

struct CreateTransactionRequest: Encodable {
    let description: String
    let amount: Int
    let date: String         // YYYY-MM-DD
    let type: String
    let paymentMethod: String
    let installmentTotal: Int
}

extension NewTransaction {
    func toRequest() -> CreateTransactionRequest {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        return CreateTransactionRequest(
            description: description,
            amount: amount,
            date: formatter.string(from: date),
            type: type.rawValue,
            paymentMethod: paymentMethod.rawValue,
            installmentTotal: installmentTotal
        )
    }
}
