//
//  APIService.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import Foundation
import UIKit

//Sets up the APIRequest framework and works with APIService to handle all network calls throughout the app

//create protocol that all APIServices will use and determine initial variables
protocol APIRequest {
    associatedtype Response
    associatedtype IsImage
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
    var postData: Data? { get }
}

//default the host name & port
extension APIRequest {
    var host: String { "austinmclaughlin.com" }
    var port: Int { 443 }
}

//set up optional values QueryItems (Get) and PostData (Post)
extension APIRequest {
    var queryItems: [URLQueryItem]? { nil }
    var postData: Data? { nil }
}

//construct URLRequest variable with the URLComponents scheme, host, port, path, queryItems, postData?
extension APIRequest {
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
        
        return request
    }
}

enum APIRequestError: Error {
    case itemsNotFound
    case requestFailed
}

//Decodable meaning Custom Objects to be returned - for example CityRequest, RestaurantRequest, corresponding usually to one table in the DB
//get the data using the path specified in APIService and decode the response
//to debug uncomment print(response), print(decoded)
extension APIRequest where Response: Decodable {
    func send() async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        
//        print(response)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIRequestError.itemsNotFound }
                
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Response.self, from: data)
//            print(decoded)
            return decoded
        } catch {
//            print(error)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        return decoded
    }
}

enum ImageRequestError: Error {
    case couldNotInitializeFromData
    case imageDataMissing
}

//get an image from the server using a specified Path from ImageRequest
extension APIRequest where Response == UIImage {
    func send() async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ImageRequestError.imageDataMissing }
        guard let image = UIImage(data: data) else { throw ImageRequestError.couldNotInitializeFromData }
        return image
    }
}

//post an image to the server using a specified path and body
extension APIRequest where IsImage == Bool {
    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        
        if let data = postData {
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\("Boundary-18IndyPeyton18 Swift Boundary")", forHTTPHeaderField: "Content-Type")
            request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
            request.httpBody = data
        }
//        print(request)
        
        return request
    }
}

//post data to the server using Post data and return a status and message as a String:String dictionary
extension APIRequest where Response == Dictionary<String, String> {
    func send() async throws -> Dictionary<String, String> {
        let(data, response) = try await URLSession.shared.data(for: request)
//        print(response)
//        if let text = String(data: data, encoding: .utf8) {
//            print("🚨 raw server response:\n\(text)")
//        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw APIRequestError.requestFailed}
        
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Response.self, from: data)
            
//            print(decoded)
            return decoded
        } catch {
//            print(error)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        
        return decoded
    }
    
}
