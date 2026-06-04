import XCTest
@testable import Ledge

final class RegisterUseCaseTests: XCTestCase {
    // MARK: - Helpers

    private func makeSUT(
        registerResult: Result<Void, Error> = .success(())
    ) -> (sut: RegisterUseCase, repository: MockAuthRepository) {
        let repository = MockAuthRepository()
        repository.registerResult = registerResult
        let sut = RegisterUseCase(repository: repository)
        return (sut, repository)
    }

    // MARK: - Success

    func test_execute_withValidInput_completesWithoutError() async throws {
        // Given
        let (sut, _) = makeSUT()

        // When / Then
        try await sut.execute(email: "user@test.com", password: "123456", confirmPassword: "123456")
    }

    func test_execute_trimsAndLowercasesEmail() async throws {
        // Given
        let (sut, repository) = makeSUT()

        // When
        try await sut.execute(email: "  User@Test.COM  ", password: "123456", confirmPassword: "123456")

        // Then
        XCTAssertEqual(repository.lastRegisterEmail, "user@test.com")
    }

    // MARK: - Validation errors

    func test_execute_withEmptyEmail_throwsInvalidEmail() async {
        // Given
        let (sut, _) = makeSUT()

        // When / Then
        await assertThrows(RegisterError.invalidEmail) {
            try await sut.execute(email: "", password: "123456", confirmPassword: "123456")
        }
    }

    func test_execute_withEmailWithoutAt_throwsInvalidEmail() async {
        // Given
        let (sut, _) = makeSUT()

        // When / Then
        await assertThrows(RegisterError.invalidEmail) {
            try await sut.execute(email: "invalidemail", password: "123456", confirmPassword: "123456")
        }
    }

    func test_execute_withShortPassword_throwsPasswordTooShort() async {
        // Given
        let (sut, _) = makeSUT()

        // When / Then
        await assertThrows(RegisterError.passwordTooShort) {
            try await sut.execute(email: "user@test.com", password: "12345", confirmPassword: "12345")
        }
    }

    func test_execute_withMismatchedPasswords_throwsPasswordMismatch() async {
        // Given
        let (sut, _) = makeSUT()

        // When / Then
        await assertThrows(RegisterError.passwordMismatch) {
            try await sut.execute(email: "user@test.com", password: "123456", confirmPassword: "999999")
        }
    }

    // MARK: - Repository error passthrough

    func test_execute_whenRepositoryFails_propagatesError() async {
        // Given
        let (sut, _) = makeSUT(
            registerResult: .failure(APIError.httpError(statusCode: 409, message: "Email already in use"))
        )

        // When / Then
        do {
            try await sut.execute(email: "user@test.com", password: "123456", confirmPassword: "123456")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
