import Foundation

enum AppEnvironment {
    case development
    case production

    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var baseURL: URL {
        guard
            let raw = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
            let url = URL(string: raw)
        else {
            fatalError("API_BASE_URL não configurado. Copie Configs/Dev.xcconfig.example para Configs/Dev.xcconfig.")
        }
        return url
    }
}
