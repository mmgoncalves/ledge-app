import XCTest
@testable import Ledge

final class GetCyclesUseCaseTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(repository: MockBillingCycleRepository = MockBillingCycleRepository())
        -> (sut: GetCyclesUseCase, repository: MockBillingCycleRepository)
    {
        (GetCyclesUseCase(repository: repository), repository)
    }

    // MARK: - Happy path

    func test_execute_returnsCycles() async throws {
        // given
        let (sut, repo) = makeSUT()
        let expected = [
            BillingCycle.fixture(id: "cycle-1"),
            BillingCycle.fixture(id: "cycle-2")
        ]
        repo.stubCycles = expected

        // when
        let result = try await sut.execute()

        // then
        XCTAssertEqual(result, expected)
    }

    func test_execute_returnsEmptyList_whenNoCyclesExist() async throws {
        // given
        let (sut, repo) = makeSUT()
        repo.stubCycles = []

        // when
        let result = try await sut.execute()

        // then
        XCTAssertTrue(result.isEmpty)
    }

    func test_execute_callsRepository() async throws {
        // given
        let (sut, repo) = makeSUT()

        // when
        _ = try await sut.execute()

        // then
        XCTAssertTrue(repo.getCyclesCalled)
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
