import SwiftUI

struct AuthView: View {
    @State private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    header
                    form
                    errorLabel
                    submitButton
                    toggleModeButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
        }
    }
}

// MARK: - Subviews

private extension AuthView {
    var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundStyle(.blue)

            Text("Ledge")
                .font(.largeTitle.bold())

            Text(viewModel.mode == .login ? "Bem-vindo de volta" : "Crie sua conta")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var form: some View {
        VStack(spacing: 16) {
            TextField("E-mail", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(.roundedBorder)

            SecureField("Senha", text: $viewModel.password)
                .textContentType(viewModel.mode == .login ? .password : .newPassword)
                .textFieldStyle(.roundedBorder)

            if viewModel.mode == .register {
                SecureField("Confirmar senha", text: $viewModel.confirmPassword)
                    .textContentType(.newPassword)
                    .textFieldStyle(.roundedBorder)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.mode)
    }

    @ViewBuilder
    var errorLabel: some View {
        if let message = viewModel.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .transition(.opacity)
        }
    }

    var submitButton: some View {
        Button {
            Task { await viewModel.submit() }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.submitLabel)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.isLoading)
    }

    var toggleModeButton: some View {
        Button(viewModel.toggleModeLabel) {
            withAnimation { viewModel.toggleMode() }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}
