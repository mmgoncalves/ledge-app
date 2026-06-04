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

    // swiftlint:disable force_unwrapping
    var baseURL: URL {
        switch self {
        case .development:
            // URL do servidor de desenvolvimento — HTTP permitido via NSAllowsArbitraryLoads no Info.plist
            return URL(string: "http://79.143.185.70:3000")!
        case .production:
            return URL(string: "https://api.ledge.app")!
        }
    }
    // swiftlint:enable force_unwrapping
}
