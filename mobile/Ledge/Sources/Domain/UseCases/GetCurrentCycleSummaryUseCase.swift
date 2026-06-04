import Foundation

protocol GetCurrentCycleSummaryUseCaseProtocol {
    /// Retorna o ciclo atual e seu resumo financeiro.
    /// Retorna `nil` se não houver ciclo ativo.
    func execute() async throws -> (cycle: BillingCycle, summary: CycleSummary)?
}

final class GetCurrentCycleSummaryUseCase: GetCurrentCycleSummaryUseCaseProtocol {

    // MARK: - Dependencies

    private let repository: BillingCycleRepository

    // MARK: - Init

    init(repository: BillingCycleRepository) {
        self.repository = repository
    }

    // MARK: - GetCurrentCycleSummaryUseCaseProtocol

    func execute() async throws -> (cycle: BillingCycle, summary: CycleSummary)? {
        guard let cycle = try await repository.getCurrentCycle() else {
            return nil
        }
        let summary = try await repository.getCycleSummary(cycleId: cycle.id)
        return (cycle: cycle, summary: summary)
    }
}
