import Foundation

struct Transaction: Identifiable, Equatable {
    let id: String
    let description: String
    let amount: Int // centavos
    let date: Date
    let type: TransactionType
    let paymentMethod: PaymentMethod
    let installmentIndex: Int?
    let installmentTotal: Int?
}

enum TransactionType: String, Equatable {
    case essential = "ESSENTIAL"
    case nonEssential = "NON_ESSENTIAL"
    case income = "INCOME"

    var label: String {
        switch self {
        case .essential: return "Essencial"
        case .nonEssential: return "Não essencial"
        case .income: return "Receita"
        }
    }

    var systemIcon: String {
        switch self {
        case .essential: return "house.fill"
        case .nonEssential: return "cart.fill"
        case .income: return "arrow.down.circle.fill"
        }
    }
}

enum PaymentMethod: String, Equatable {
    case creditCard = "CREDIT_CARD"
    case debitCard = "DEBIT_CARD"
    case pix = "PIX"
    case cash = "CASH"

    var label: String {
        switch self {
        case .creditCard: return "Crédito"
        case .debitCard: return "Débito"
        case .pix: return "Pix"
        case .cash: return "Dinheiro"
        }
    }
}
