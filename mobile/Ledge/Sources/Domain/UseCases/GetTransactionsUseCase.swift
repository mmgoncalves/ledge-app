import Foundation

protocol GetTransactionsUseCaseProtocol {
    func execute(cycleId: String) async throws -> [Transaction]
}

final class GetTransactionsUseCase: GetTransactionsUseCaseProtocol {

    private let repository: BillingCycleRepository

    init(repository: BillingCycleRepository) {
        self.repository = repository
    }

    func execute(cycleId: String) async throws -> [Transaction] {
        try await repository.getTransactions(cycleId: cycleId)
    }
}
