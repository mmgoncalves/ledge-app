import Foundation

/// Resumo financeiro de um ciclo de fatura.
/// Todos os valores em centavos.
struct CycleSummary: Equatable {
    let totalIncome: Int
    let totalEssential: Int
    let totalNonEssential: Int
    let balance: Int
    let transactionCount: Int
}
