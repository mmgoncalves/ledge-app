import Foundation

final class RegisterUseCase {
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute(email: String, password: String, confirmPassword: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedEmail.isEmpty, trimmedEmail.contains("@") else {
            throw RegisterError.invalidEmail
        }
        guard password.count >= 6 else {
            throw RegisterError.passwordTooShort
        }
        guard password == confirmPassword else {
            throw RegisterError.passwordMismatch
        }

        try await repository.register(email: trimmedEmail, password: password)
    }
}

enum RegisterError: LocalizedError, Equatable {
    case invalidEmail
    case passwordTooShort
    case passwordMismatch

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Informe um e-mail válido."
        case .passwordTooShort: return "A senha deve ter pelo menos 6 caracteres."
        case .passwordMismatch: return "As senhas não coincidem."
        }
    }
}
