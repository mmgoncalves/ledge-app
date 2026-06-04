import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterResponse: Decodable {
    let id: String
    let email: String
}
