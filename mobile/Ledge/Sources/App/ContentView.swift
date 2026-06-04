import SwiftUI

@Observable
final class AppState {
    var isAuthenticated: Bool

    private let keychain: KeychainServiceProtocol

    init(keychain: KeychainServiceProtocol = KeychainService.shared) {
        self.keychain = keychain
        self.isAuthenticated = (try? keychain.loadToken()) != nil
    }

    func logout() {
        try? keychain.deleteToken()
        isAuthenticated = false
    }
}

struct ContentView: View {
    @State private var appState = AppState()

    var body: some View {
        if appState.isAuthenticated {
            HomeView(onLogout: appState.logout)
        } else {
            AuthView(viewModel: makeAuthViewModel())
        }
    }

    private func makeAuthViewModel() -> AuthViewModel {
        let repository = AuthRepositoryImpl()
        let viewModel = AuthViewModel(
            loginUseCase: LoginUseCase(repository: repository),
            registerUseCase: RegisterUseCase(repository: repository)
        )
        viewModel.onAuthenticated = { appState.isAuthenticated = true }
        return viewModel
    }
}

