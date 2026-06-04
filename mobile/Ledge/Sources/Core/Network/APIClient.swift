import Foundation

final class APIClient {
    private let environment: AppEnvironment
    private let session: URLSession
    private let decoder: JSONDecoder

    init(environment: AppEnvironment = .current, session: URLSession = .shared) {
        self.environment = environment
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    func post<RequestBody: Encodable, Response: Decodable>(
        path: String,
        body: RequestBody,
        token: String? = nil
    ) async throws -> Response {
        let request = try buildRequest(method: "POST", path: path, body: body, token: token)
        return try await perform(request)
    }

    func get<Response: Decodable>(
        path: String,
        token: String
    ) async throws -> Response {
        let request = try buildRequest(method: "GET", path: path, body: Optional<String>.none, token: token)
        return try await perform(request)
    }
}

// MARK: - Private

private extension APIClient {
    func buildRequest<Body: Encodable>(
        method: String,
        path: String,
        body: Body?,
        token: String?
    ) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: environment.baseURL) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }

    func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let message = (try? decoder.decode(ErrorResponse.self, from: data))?.error
            throw APIError.httpError(statusCode: http.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}

// MARK: - Internal

struct ErrorResponse: Decodable {
    let error: String
}
