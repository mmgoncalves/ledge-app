import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let client: APIClient

    init(client: APIClient = APIClient()) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> AuthToken {
        let response: LoginResponse = try await client.post(
            path: "auth/login",
            body: LoginRequest(email: email, password: password)
        )
        return AuthToken(value: response.token)
    }

    func register(email: String, password: String) async throws {
        let _: RegisterResponse = try await client.post(
            path: "auth/register",
            body: RegisterRequest(email: email, password: password)
        )
    }
}
