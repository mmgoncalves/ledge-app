import Foundation

protocol ExportDataUseCaseProtocol {
    func execute(format: ExportFormat) async throws -> Data
}

final class ExportDataUseCase: ExportDataUseCaseProtocol {
    private let repository: ExportRepository

    init(repository: ExportRepository) {
        self.repository = repository
    }

    func execute(format: ExportFormat) async throws -> Data {
        try await repository.export(format: format)
    }
}
