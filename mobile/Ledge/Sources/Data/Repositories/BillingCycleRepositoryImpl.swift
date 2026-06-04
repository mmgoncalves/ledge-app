import Foundation

final class BillingCycleRepositoryImpl: BillingCycleRepository {

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

    // MARK: - BillingCycleRepository

    func getCurrentCycle() async throws -> BillingCycle? {
        let token = try requireToken()
        do {
            let response: BillingCycleResponse = try await client.get(
                path: "cycles/current",
                token: token
            )
            return response.toDomain()
        } catch APIError.httpError(let statusCode, _) where statusCode == 404 {
            return nil
        }
    }

    func getCycleSummary(cycleId: String) async throws -> CycleSummary {
        let token = try requireToken()
        let response: CycleSummaryResponse = try await client.get(
            path: "cycles/\(cycleId)/summary",
            token: token
        )
        return response.toDomain()
    }

    func getTransactions(cycleId: String) async throws -> [Transaction] {
        let token = try requireToken()
        let responses: [TransactionResponse] = try await client.get(
            path: "cycles/\(cycleId)/transactions",
            token: token
        )
        return responses.compactMap { $0.toDomain() }
    }

    func getCycleNeighbors(cycleId: String) async throws -> CycleNeighbors {
        let token = try requireToken()
        let response: CycleNeighborsResponse = try await client.get(
            path: "cycles/\(cycleId)/neighbors",
            token: token
        )
        return response.toDomain()
    }

    // MARK: - Private

    private func requireToken() throws -> String {
        guard let token = try keychain.loadToken() else {
            throw APIError.httpError(statusCode: 401, message: "Sessão expirada. Faça login novamente.")
        }
        return token
    }
}
