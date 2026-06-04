import Foundation

protocol AuthRepository {
    func login(email: String, password: String) async throws -> AuthToken
    func register(email: String, password: String) async throws
}
