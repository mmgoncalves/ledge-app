import Foundation

final class TransactionRepositoryImpl: TransactionRepository {

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

    // MARK: - TransactionRepository

    func createTransaction(cycleId: String, input: NewTransaction) async throws -> Transaction {
        let token = try requireToken()
        let body = input.toRequest()
        // O backend retorna um array (uma entrada por parcela criada).
        let responses: [TransactionResponse] = try await client.post(
            path: "cycles/\(cycleId)/transactions",
            body: body,
            token: token
        )
        guard let first = responses.first, let transaction = first.toDomain() else {
            throw APIError.httpError(statusCode: 500, message: "Resposta inválida do servidor")
        }
        return transaction
    }

    // MARK: - Private

    private func requireToken() throws -> String {
        guard let token = try keychain.loadToken() else {
            throw APIError.httpError(statusCode: 401, message: "Sessão expirada. Faça login novamente.")
        }
        return token
    }
}
