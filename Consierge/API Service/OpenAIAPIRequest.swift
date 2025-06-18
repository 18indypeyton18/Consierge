//
//  OpenAIAPIRequest.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/20/25.
//

import Foundation

protocol OpenAIAPIRequest {
    associatedtype Response: Decodable

    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    var request: URLRequest { get }
}

// Default Host and Headers
extension OpenAIAPIRequest {
    var host: String { "api.openai.com" }
    var port: Int { 443 }
    var apiKey: String { apiToken }

    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        return request
    }
}

extension OpenAIAPIRequest {
    func send() async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // print(response)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAIAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch response"])
        }
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Response.self, from: data)
            // print(decoded)
            return decoded
        } catch {
            // print(error)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        return decoded
    }
}
