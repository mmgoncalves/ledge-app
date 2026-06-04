import XCTest
@testable import Ledge

// MARK: - Mock

final class MockBillingCycleRepository: BillingCycleRepository {

    // MARK: - Stubs

    var stubCurrentCycle: BillingCycle? = .fixture()
    var stubSummary: CycleSummary = .fixture()
    var stubTransactions: [Transaction] = []
    var stubNeighbors: CycleNeighbors = CycleNeighbors(previous: nil, next: nil)
    var stubError: Error?

    // MARK: - Call tracking

    private(set) var getCurrentCycleCalled = false
    private(set) var getCycleSummaryCalled = false
    private(set) var getTransactionsCalled = false
    private(set) var getCycleNeighborsCalled = false
    private(set) var lastSummaryRequestedCycleId: String?
    private(set) var lastTransactionsRequestedCycleId: String?
    private(set) var lastNeighborsRequestedCycleId: String?

    // MARK: - BillingCycleRepository

    func getCurrentCycle() async throws -> BillingCycle? {
        getCurrentCycleCalled = true
        if let error = stubError { throw error }
        return stubCurrentCycle
    }

    func getCycleSummary(cycleId: String) async throws -> CycleSummary {
        getCycleSummaryCalled = true
        lastSummaryRequestedCycleId = cycleId
        if let error = stubError { throw error }
        return stubSummary
    }

    func getTransactions(cycleId: String) async throws -> [Transaction] {
        getTransactionsCalled = true
        lastTransactionsRequestedCycleId = cycleId
        if let error = stubError { throw error }
        return stubTransactions
    }

    func getCycleNeighbors(cycleId: String) async throws -> CycleNeighbors {
        getCycleNeighborsCalled = true
        lastNeighborsRequestedCycleId = cycleId
        if let error = stubError { throw error }
        return stubNeighbors
    }
}

// MARK: - Fixtures

extension BillingCycle {
    static func fixture(
        id: String = "cycle-uuid",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(30 * 24 * 3600),
        cutDay: Int = 10
    ) -> BillingCycle {
        BillingCycle(id: id, startDate: startDate, endDate: endDate, cutDay: cutDay)
    }
}

extension CycleSummary {
    static func fixture(
        totalIncome: Int = 500_000,
        totalEssential: Int = 200_000,
        totalNonEssential: Int = 50_000,
        balance: Int = 250_000,
        transactionCount: Int = 10
    ) -> CycleSummary {
        CycleSummary(
            totalIncome: totalIncome,
            totalEssential: totalEssential,
            totalNonEssential: totalNonEssential,
            balance: balance,
            transactionCount: transactionCount
        )
    }
}

// MARK: - Tests

final class GetCurrentCycleSummaryUseCaseTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(repository: MockBillingCycleRepository = MockBillingCycleRepository())
        -> (sut: GetCurrentCycleSummaryUseCase, repository: MockBillingCycleRepository)
    {
        (GetCurrentCycleSummaryUseCase(repository: repository), repository)
    }

    // MARK: - Happy path

    func test_execute_returnsCycleAndSummary_whenCycleExists() async throws {
        // given
        let (sut, repo) = makeSUT()
        let expectedCycle = BillingCycle.fixture(id: "cycle-1")
        let expectedSummary = CycleSummary.fixture(totalIncome: 100_000)
        repo.stubCurrentCycle = expectedCycle
        repo.stubSummary = expectedSummary

        // when
        let result = try await sut.execute()

        // then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.cycle, expectedCycle)
        XCTAssertEqual(result?.summary, expectedSummary)
    }

    func test_execute_callsGetCurrentCycle() async throws {
        // given
        let (sut, repo) = makeSUT()

        // when
        _ = try await sut.execute()

        // then
        XCTAssertTrue(repo.getCurrentCycleCalled)
    }

    func test_execute_callsGetCycleSummaryWithCorrectId() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubCurrentCycle = BillingCycle.fixture(id: "cycle-abc")

        // when
        _ = try await sut.execute()

        // then
        XCTAssertTrue(repo.getCycleSummaryCalled)
        XCTAssertEqual(repo.lastSummaryRequestedCycleId, "cycle-abc")
    }

    // MARK: - No active cycle

    func test_execute_returnsNil_whenNoCycleExists() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubCurrentCycle = nil

        // when
        let result = try await sut.execute()

        // then
        XCTAssertNil(result)
    }

    func test_execute_doesNotCallGetSummary_whenNoCycleExists() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubCurrentCycle = nil

        // when
        _ = try await sut.execute()

        // then
        XCTAssertFalse(repo.getCycleSummaryCalled)
    }

    // MARK: - Error handling

    func test_execute_throws_whenRepositoryThrows() async {
        // given
        let (sut, repo) = makeSUT()
        repo.stubError = APIError.network(URLError(.notConnectedToInternet))

        // when / then
        await XCTAssertThrowsErrorAsync(try await sut.execute())
    }
}

// MARK: - Async test helper

func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {}
}
