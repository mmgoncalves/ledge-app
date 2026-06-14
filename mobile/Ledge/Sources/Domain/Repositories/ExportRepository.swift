import Foundation

protocol ExportRepository: AnyObject {
    func export(format: ExportFormat) async throws -> Data
}
