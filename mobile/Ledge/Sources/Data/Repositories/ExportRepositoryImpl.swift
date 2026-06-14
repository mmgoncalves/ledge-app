import Foundation

final class ExportRepositoryImpl: ExportRepository {

    // MARK: - Dependencies

    private let client: APIClient
    private let keychain: KeychainServiceProtocol

    // MARK: - Init

    init(
        client: APIClient = APIClient(),
        keychain: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.client = client
        self.keychain = keychain
    }

    // MARK: - ExportRepository

    func export(format: ExportFormat) async throws -> Data {
        let token = try requireToken()
        return try await client.getRawData(
            path: "export",
            queryItems: [URLQueryItem(name: "format", value: format.rawValue)],
            token: token
        )
    }

    // MARK: - Private

    private func requireToken() throws -> String {
        guard let token = try keychain.loadToken() else {
            throw APIError.httpError(statusCode: 401, message: "Sessão expirada. Faça login novamente.")
        }
        return token
    }
}
