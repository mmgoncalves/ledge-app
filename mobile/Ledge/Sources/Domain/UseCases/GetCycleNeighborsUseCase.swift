import Foundation

protocol GetCycleNeighborsUseCaseProtocol {
    func execute(cycleId: String) async throws -> CycleNeighbors
}

final class GetCycleNeighborsUseCase: GetCycleNeighborsUseCaseProtocol {

    private let repository: BillingCycleRepository

    init(repository: BillingCycleRepository) {
        self.repository = repository
    }

    func execute(cycleId: String) async throws -> CycleNeighbors {
        try await repository.getCycleNeighbors(cycleId: cycleId)
    }
}
