import XCTest
@testable import Ledge

// MARK: - Mock

final class MockTransactionRepository: TransactionRepository {
    var createResult: Result<Transaction, Error> = .success(
        Transaction(
            id: "txn-1",
            description: "Teste",
            amount: 10000,
            date: Date(),
            type: .essential,
            paymentMethod: .pix,
            installmentIndex: nil,
            installmentTotal: nil
        )
    )

    private(set) var lastCycleId: String?
    private(set) var lastInput: NewTransaction?

    func createTransaction(cycleId: String, input: NewTransaction) async throws -> Transaction {
        lastCycleId = cycleId
        lastInput = input
        return try createResult.get()
    }
}

// MARK: - Tests

final class CreateTransactionUseCaseTests: XCTestCase {
    private var repository: MockTransactionRepository!
    private var sut: CreateTransactionUseCase!

    override func setUp() {
        super.setUp()
        repository = MockTransactionRepository()
        sut = CreateTransactionUseCase(repository: repository)
    }

    // MARK: - Success

    func test_execute_success_returnsTransaction() async throws {
        let input = NewTransaction(
            description: "Mercado",
            amount: 45000,
            date: Date(),
            type: .essential,
            paymentMethod: .debitCard,
            installmentTotal: 1
        )

        let result = try await sut.execute(cycleId: "cycle-abc", input: input)

        XCTAssertEqual(result.id, "txn-1")
    }

    func test_execute_forwardsCorrectCycleId() async throws {
        let input = NewTransaction(
            description: "Netflix",
            amount: 5500,
            date: Date(),
            type: .nonEssential,
            paymentMethod: .creditCard,
            installmentTotal: 1
        )

        _ = try await sut.execute(cycleId: "cycle-xyz", input: input)

        XCTAssertEqual(repository.lastCycleId, "cycle-xyz")
    }

    func test_execute_forwardsInputToRepository() async throws {
        let date = Date()
        let input = NewTransaction(
            description: "Salário",
            amount: 500000,
            date: date,
            type: .income,
            paymentMethod: .pix,
            installmentTotal: 1
        )

        _ = try await sut.execute(cycleId: "cycle-1", input: input)

        let forwarded = try XCTUnwrap(repository.lastInput)
        XCTAssertEqual(forwarded.description, "Salário")
        XCTAssertEqual(forwarded.amount, 500000)
        XCTAssertEqual(forwarded.type, .income)
        XCTAssertEqual(forwarded.paymentMethod, .pix)
        XCTAssertEqual(forwarded.installmentTotal, 1)
    }

    func test_execute_installment_forwardsInstallmentTotal() async throws {
        let input = NewTransaction(
            description: "TV",
            amount: 300000,
            date: Date(),
            type: .nonEssential,
            paymentMethod: .creditCard,
            installmentTotal: 6
        )

        _ = try await sut.execute(cycleId: "cycle-1", input: input)

        XCTAssertEqual(repository.lastInput?.installmentTotal, 6)
    }

    // MARK: - Error

    func test_execute_repositoryThrows_propagatesError() async {
        repository.createResult = .failure(APIError.httpError(statusCode: 422, message: "Valor inválido"))

        let input = NewTransaction(
            description: "X",
            amount: 100,
            date: Date(),
            type: .essential,
            paymentMethod: .pix,
            installmentTotal: 1
        )

        do {
            _ = try await sut.execute(cycleId: "cycle-1", input: input)
            XCTFail("Deveria ter lançado erro")
        } catch APIError.httpError(let status, _) {
            XCTAssertEqual(status, 422)
        } catch {
            XCTFail("Erro inesperado: \(error)")
        }
    }
}
