import Foundation

final class LoginUseCase {
    private let repository: AuthRepository
    private let keychain: KeychainServiceProtocol

    init(repository: AuthRepository, keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.repository = repository
        self.keychain = keychain
    }

    func execute(email: String, password: String) async throws -> AuthToken {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            throw LoginError.invalidEmail
        }
        guard password.count >= 6 else {
            throw LoginError.passwordTooShort
        }

        let token = try await repository.login(email: trimmedEmail, password: password)
        try keychain.saveToken(token.value)
        return token
    }
}

enum LoginError: LocalizedError, Equatable {
    case invalidEmail
    case passwordTooShort

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Informe um e-mail válido."
        case .passwordTooShort: return "A senha deve ter pelo menos 6 caracteres."
        }
    }
}
