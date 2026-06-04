import XCTest
@testable import Ledge

final class LoginUseCaseTests: XCTestCase {
    // MARK: - Helpers

    private func makeSUT(
        loginResult: Result<AuthToken, Error> = .success(AuthToken(value: "token-abc"))
    ) -> (sut: LoginUseCase, repository: MockAuthRepository, keychain: MockKeychainService) {
        let repository = MockAuthRepository()
        repository.loginResult = loginResult
        let keychain = MockKeychainService()
        let sut = LoginUseCase(repository: repository, keychain: keychain)
        return (sut, repository, keychain)
    }

    // MARK: - Success

    func test_execute_withValidCredentials_returnsToken() async throws {
        // Given
        let (sut, _, _) = makeSUT()

        // When
        let token = try await sut.execute(email: "user@test.com", password: "123456")

        // Then
        XCTAssertEqual(token.value, "token-abc")
    }

    func test_execute_savesTokenToKeychain() async throws {
        // Given
        let (sut, _, keychain) = makeSUT()

        // When
        _ = try await sut.execute(email: "user@test.com", password: "123456")

        // Then
        XCTAssertEqual(keychain.savedToken, "token-abc")
    }

    func test_execute_trimsAndLowercasesEmail() async throws {
        // Given
        let (sut, repository, _) = makeSUT()

        // When
        _ = try await sut.execute(email: "  User@Test.COM  ", password: "123456")

        // Then
        XCTAssertEqual(repository.lastLoginEmail, "user@test.com")
    }

    // MARK: - Validation errors

    func test_execute_withEmptyEmail_throwsInvalidEmail() async {
        // Given
        let (sut, _, _) = makeSUT()

        // When / Then
        await assertThrows(LoginError.invalidEmail) {
            try await sut.execute(email: "", password: "123456")
        }
    }

    func test_execute_withEmailWithoutAt_throwsInvalidEmail() async {
        // Given
        let (sut, _, _) = makeSUT()

        // When / Then
        await assertThrows(LoginError.invalidEmail) {
            try await sut.execute(email: "invalidemail", password: "123456")
        }
    }

    func test_execute_withShortPassword_throwsPasswordTooShort() async {
        // Given
        let (sut, _, _) = makeSUT()

        // When / Then
        await assertThrows(LoginError.passwordTooShort) {
            try await sut.execute(email: "user@test.com", password: "12345")
        }
    }

    // MARK: - Repository error passthrough

    func test_execute_whenRepositoryFails_propagatesError() async {
        // Given
        let (sut, _, _) = makeSUT(
            loginResult: .failure(APIError.httpError(statusCode: 401, message: "Invalid credentials"))
        )

        // When / Then
        do {
            _ = try await sut.execute(email: "user@test.com", password: "123456")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
