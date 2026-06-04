import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case network(Error)
    case httpError(statusCode: Int, message: String?)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida."
        case .network:
            return "Erro de conexão. Verifique sua internet."
        case .httpError(_, let message):
            return message ?? "Erro no servidor."
        case .decoding:
            return "Erro ao processar resposta do servidor."
        }
    }
}
