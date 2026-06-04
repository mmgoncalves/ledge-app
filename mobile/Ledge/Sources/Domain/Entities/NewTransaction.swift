import Foundation

/// Input para criação de um novo lançamento.
struct NewTransaction {
    let description: String
    let amount: Int          // centavos
    let date: Date
    let type: TransactionType
    let paymentMethod: PaymentMethod
    let installmentTotal: Int // 1 = à vista
}
