import Foundation

enum ExportFormat: String, CaseIterable {
    case json
    case csv

    var label: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }

    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }

    var filename: String { "ledge-export.\(rawValue)" }
}
