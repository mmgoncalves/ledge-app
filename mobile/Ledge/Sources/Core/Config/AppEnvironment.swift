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
        let info = Bundle.main.infoDictionary
        guard
            let scheme = info?["API_SCHEME"] as? String, !scheme.isEmpty,
            let host = info?["API_HOST"] as? String, !host.isEmpty,
            let url = URL(string: "\(scheme)://\(host)")
        else {
            fatalError(
                "API_SCHEME ou API_HOST não configurados. " +
                "Copie Configs/Dev.xcconfig.example para Configs/Dev.xcconfig e preencha os valores."
            )
        }
        return url
    }
}
