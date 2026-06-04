import XCTest
@testable import Ledge

// MARK: - Mock AuthRepository

final class MockAuthRepository: AuthRepository {
    var loginResult: Result<AuthToken, Error> = .success(AuthToken(value: "token-abc"))
    var registerResult: Result<Void, Error> = .success(())

    private(set) var lastLoginEmail: String?
    private(set) var lastRegisterEmail: String?

    func login(email: String, password: String) async throws -> AuthToken {
        lastLoginEmail = email
        return try loginResult.get()
    }

    func register(email: String, password: String) async throws {
        lastRegisterEmail = email
        try registerResult.get()
    }
}

// MARK: - Mock KeychainService

final class MockKeychainService: KeychainServiceProtocol {
    private(set) var savedToken: String?
    private(set) var deleteTokenCalled = false

    func saveToken(_ token: String) throws {
        savedToken = token
    }

    func loadToken() throws -> String? { savedToken }

    func deleteToken() throws {
        deleteTokenCalled = true
        savedToken = nil
    }
}

// MARK: - Assertion helper

func assertThrows<E: Error & Equatable>(
    _ expected: E,
    _ block: () async throws -> Void,
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        try await block()
        XCTFail("Expected \(expected) but no error was thrown", file: file, line: line)
    } catch let error as E {
        XCTAssertEqual(error, expected, file: file, line: line)
    } catch {
        XCTFail("Expected \(expected) but got \(error)", file: file, line: line)
    }
}
