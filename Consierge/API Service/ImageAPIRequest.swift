//
//  ImageAPIRequest.swift
//  Consierge
//
//  Created by Austin McLaughlin on 5/28/25.
//

import Foundation
import UIKit

//Sets up the APIRequest framework and works with APIService to handle all network calls throughout the app

//create protocol that all APIServices will use and determine initial variables
protocol ImageAPIRequest {
    associatedtype Response
    associatedtype IsImage
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
    var postData: Data? { get }
}

//default the host name & port
extension ImageAPIRequest {
    var host: String { "d2e07sdeqwplr.cloudfront.net" }
    var port: Int { 443 }
}

//set up optional values QueryItems (Get) and PostData (Post)
extension ImageAPIRequest {
    var queryItems: [URLQueryItem]? { nil }
    var postData: Data? { nil }
}

//construct URLRequest variable with the URLComponents scheme, host, port, path, queryItems, postData?
extension ImageAPIRequest {
    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        
        if let data = postData {
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
        }
//        print("request", request)
        
        return request
    }
}

extension ImageAPIRequest where Response == UIImage {
    func send() async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ImageRequestError.imageDataMissing }
        guard let image = UIImage(data: data) else { throw ImageRequestError.couldNotInitializeFromData }
        return image
    }
}
