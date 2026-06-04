import Foundation

enum AuthMode {
    case login
    case register
}

@Observable
final class AuthViewModel {
    var mode: AuthMode = .login
    var email: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isLoading: Bool = false
    var errorMessage: String?

    var onAuthenticated: (() -> Void)?

    private let loginUseCase: LoginUseCase
    private let registerUseCase: RegisterUseCase

    init(
        loginUseCase: LoginUseCase,
        registerUseCase: RegisterUseCase
    ) {
        self.loginUseCase = loginUseCase
        self.registerUseCase = registerUseCase
    }

    var toggleModeLabel: String {
        switch mode {
        case .login: return "Não tem conta? Registre-se"
        case .register: return "Já tem conta? Entrar"
        }
    }

    var submitLabel: String {
        switch mode {
        case .login: return "Entrar"
        case .register: return "Criar conta"
        }
    }

    func toggleMode() {
        mode = mode == .login ? .register : .login
        errorMessage = nil
    }

    func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .login:
                try await loginUseCase.execute(email: email, password: password)
                onAuthenticated?()

            case .register:
                try await registerUseCase.execute(
                    email: email,
                    password: password,
                    confirmPassword: confirmPassword
                )
                // Auto-login after register
                try await loginUseCase.execute(email: email, password: password)
                onAuthenticated?()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
