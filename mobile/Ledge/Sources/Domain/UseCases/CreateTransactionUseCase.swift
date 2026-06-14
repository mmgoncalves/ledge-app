protocol CreateTransactionUseCaseProtocol {
    func execute(cycleId: String, input: NewTransaction) async throws -> Transaction
}

final class CreateTransactionUseCase: CreateTransactionUseCaseProtocol {
    private let repository: TransactionRepository

    init(repository: TransactionRepository) {
        self.repository = repository
    }

    func execute(cycleId: String, input: NewTransaction) async throws -> Transaction {
        try await repository.createTransaction(cycleId: cycleId, input: input)
    }
}
