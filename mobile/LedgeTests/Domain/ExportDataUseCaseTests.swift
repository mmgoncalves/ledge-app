import XCTest
@testable import Ledge

final class ExportDataUseCaseTests: XCTestCase {

    // MARK: - Doubles

    private final class MockExportRepository: ExportRepository {
        var result: Result<Data, Error> = .success(Data())

        func export(format: ExportFormat) async throws -> Data {
            switch result {
            case .success(let data): return data
            case .failure(let error): throw error
            }
        }
    }

    // MARK: - Tests

    func test_execute_json_returnsDataFromRepository() async throws {
        // Given
        let expected = Data("{\"cycles\":[]}".utf8)
        let repository = MockExportRepository()
        repository.result = .success(expected)
        let sut = ExportDataUseCase(repository: repository)

        // When
        let result = try await sut.execute(format: .json)

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_execute_csv_returnsDataFromRepository() async throws {
        // Given
        let expected = Data("id,startDate\n".utf8)
        let repository = MockExportRepository()
        repository.result = .success(expected)
        let sut = ExportDataUseCase(repository: repository)

        // When
        let result = try await sut.execute(format: .csv)

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        let repository = MockExportRepository()
        repository.result = .failure(APIError.httpError(statusCode: 401, message: "Não autorizado"))
        let sut = ExportDataUseCase(repository: repository)

        // When / Then
        do {
            _ = try await sut.execute(format: .json)
            XCTFail("Expected error to be thrown")
        } catch APIError.httpError(let statusCode, _) {
            XCTAssertEqual(statusCode, 401)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_exportFormat_json_hasCorrectProperties() {
        XCTAssertEqual(ExportFormat.json.rawValue, "json")
        XCTAssertEqual(ExportFormat.json.filename, "ledge-export.json")
        XCTAssertEqual(ExportFormat.json.mimeType, "application/json")
        XCTAssertEqual(ExportFormat.json.label, "JSON")
    }

    func test_exportFormat_csv_hasCorrectProperties() {
        XCTAssertEqual(ExportFormat.csv.rawValue, "csv")
        XCTAssertEqual(ExportFormat.csv.filename, "ledge-export.csv")
        XCTAssertEqual(ExportFormat.csv.mimeType, "text/csv")
        XCTAssertEqual(ExportFormat.csv.label, "CSV")
    }

    func test_exportFormat_allCases_containsJsonAndCsv() {
        let cases = ExportFormat.allCases
        XCTAssertTrue(cases.contains(.json))
        XCTAssertTrue(cases.contains(.csv))
        XCTAssertEqual(cases.count, 2)
    }
}
