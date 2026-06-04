import Foundation

/// Interface para acesso aos ciclos de fatura.
///
/// Vive no Domain — sem imports de Foundation além do necessário.
protocol BillingCycleRepository: AnyObject {
    /// Retorna o ciclo ativo no momento, ou `nil` se não houver nenhum.
    func getCurrentCycle() async throws -> BillingCycle?

    /// Retorna o resumo financeiro de um ciclo específico.
    func getCycleSummary(cycleId: String) async throws -> CycleSummary
}
