import XCTest
@testable import Ledge

// MARK: - Fixtures

extension Transaction {
    static func fixture(
        id: String = "txn-uuid",
        description: String = "Supermercado",
        amount: Int = 45_000,
        date: Date = Date(),
        type: TransactionType = .essential,
        paymentMethod: PaymentMethod = .debitCard,
        installmentIndex: Int? = nil,
        installmentTotal: Int? = nil
    ) -> Transaction {
        Transaction(
            id: id,
            description: description,
            amount: amount,
            date: date,
            type: type,
            paymentMethod: paymentMethod,
            installmentIndex: installmentIndex,
            installmentTotal: installmentTotal
        )
    }
}

// MARK: - Tests

final class GetTransactionsUseCaseTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(repository: MockBillingCycleRepository = MockBillingCycleRepository())
        -> (sut: GetTransactionsUseCase, repository: MockBillingCycleRepository)
    {
        (GetTransactionsUseCase(repository: repository), repository)
    }

    // MARK: - Happy path

    func test_execute_returnsTransactions_whenCycleHasTransactions() async throws {
        // given
        let (sut, repo) = makeSUT()
        let expected = [
            Transaction.fixture(id: "txn-1", description: "Salário", amount: 500_000, type: .income),
            Transaction.fixture(id: "txn-2", description: "Aluguel", amount: 150_000, type: .essential)
        ]
        repo.stubTransactions = expected

        // when
        let result = try await sut.execute(cycleId: "cycle-1")

        // then
        XCTAssertEqual(result, expected)
    }

    func test_execute_returnsEmptyList_whenCycleHasNoTransactions() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubTransactions = []

        // when
        let result = try await sut.execute(cycleId: "cycle-1")

        // then
        XCTAssertTrue(result.isEmpty)
    }

    func test_execute_callsRepositoryWithCorrectCycleId() async throws {
        // given
        let (sut, repo) = makeSUT()
        let cycleId = "cycle-abc-123"

        // when
        _ = try await sut.execute(cycleId: cycleId)

        // then
        XCTAssertTrue(repo.getTransactionsCalled)
        XCTAssertEqual(repo.lastTransactionsRequestedCycleId, cycleId)
    }

    // MARK: - Error handling

    func test_execute_throws_whenRepositoryThrows() async {
        // given
        let (sut, repo) = makeSUT()
        repo.stubError = APIError.network(URLError(.notConnectedToInternet))

        // when / then
        await XCTAssertThrowsErrorAsync(try await sut.execute(cycleId: "cycle-1"))
    }
}
