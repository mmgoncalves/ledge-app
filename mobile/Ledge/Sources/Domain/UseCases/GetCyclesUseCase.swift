import Foundation

protocol GetCyclesUseCaseProtocol {
    func execute() async throws -> [BillingCycle]
}

final class GetCyclesUseCase: GetCyclesUseCaseProtocol {

    private let repository: BillingCycleRepository

    init(repository: BillingCycleRepository) {
        self.repository = repository
    }

    func execute() async throws -> [BillingCycle] {
        try await repository.getCycles()
    }
}
