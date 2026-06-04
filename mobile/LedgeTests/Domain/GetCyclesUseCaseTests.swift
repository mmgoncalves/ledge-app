import XCTest
@testable import Ledge

// MARK: - Fixtures

extension CycleNeighbors {
    static func fixture(
        previous: BillingCycle? = nil,
        next: BillingCycle? = nil
    ) -> CycleNeighbors {
        CycleNeighbors(previous: previous, next: next)
    }
}

// MARK: - Tests

final class GetCycleNeighborsUseCaseTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(repository: MockBillingCycleRepository = MockBillingCycleRepository())
        -> (sut: GetCycleNeighborsUseCase, repository: MockBillingCycleRepository)
    {
        (GetCycleNeighborsUseCase(repository: repository), repository)
    }

    // MARK: - Happy path

    func test_execute_returnsBothNeighbors_whenCycleIsInTheMiddle() async throws {
        // given
        let (sut, repo) = makeSUT()
        let previous = BillingCycle.fixture(id: "cycle-may")
        let next = BillingCycle.fixture(id: "cycle-july")
        repo.stubNeighbors = CycleNeighbors(previous: previous, next: next)

        // when
        let result = try await sut.execute(cycleId: "cycle-june")

        // then
        XCTAssertEqual(result.previous, previous)
        XCTAssertEqual(result.next, next)
    }

    func test_execute_returnsPreviousNil_whenCycleIsOldest() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubNeighbors = CycleNeighbors(previous: nil, next: .fixture(id: "cycle-next"))

        // when
        let result = try await sut.execute(cycleId: "cycle-oldest")

        // then
        XCTAssertNil(result.previous)
        XCTAssertNotNil(result.next)
    }

    func test_execute_returnsNextNil_whenCycleIsMostRecent() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubNeighbors = CycleNeighbors(previous: .fixture(id: "cycle-prev"), next: nil)

        // when
        let result = try await sut.execute(cycleId: "cycle-latest")

        // then
        XCTAssertNotNil(result.previous)
        XCTAssertNil(result.next)
    }

    func test_execute_returnsBothNil_whenCycleIsAlone() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubNeighbors = CycleNeighbors(previous: nil, next: nil)

        // when
        let result = try await sut.execute(cycleId: "cycle-only")

        // then
        XCTAssertNil(result.previous)
        XCTAssertNil(result.next)
    }

    func test_execute_callsRepositoryWithCorrectCycleId() async throws {
        // given
        let (sut, repo) = makeSUT()
        let cycleId = "cycle-abc-123"

        // when
        _ = try await sut.execute(cycleId: cycleId)

        // then
        XCTAssertTrue(repo.getCycleNeighborsCalled)
        XCTAssertEqual(repo.lastNeighborsRequestedCycleId, cycleId)
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
