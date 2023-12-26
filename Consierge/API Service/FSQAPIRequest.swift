//
//  FSQAPIRequest.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/19/24.
//
import UIKit

//Sets up the APIRequest framework and works with APIService to handle all network calls throughout the app

//create protocol that all APIServices will use and determine initial variables
protocol FSQAPIRequest {
    associatedtype Response
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
}

//default the host name & port
extension FSQAPIRequest {
    var host: String { "api.foursquare.com" }
    var port: Int { 443 }
}

//set up optional values QueryItems (Get) and PostData (Post)
extension FSQAPIRequest {
    var queryItems: [URLQueryItem]? { nil }
}

//construct URLRequest variable with the URLComponents scheme, host, port, path, queryItems, postData?
extension FSQAPIRequest {
    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        
        request.setValue("fsq3t540xPfIQrne3qM2JVdQ447g3FxG3GvXAZ85+zVL3MQ=", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        return request
    }
}

enum FSQAPIRequestError: Error {
    case itemsNotFound
    case requestFailed
}

//Decodable meaning Custom Objects to be returned - for example CityRequest, RestaurantRequest, corresponding usually to one table in the DB
//get the data using the path specified in APIService and decode the response
//to debug uncomment print(response), print(decoded)
extension FSQAPIRequest where Response: Decodable {
    func send() async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        //print("FSQAPIRequest Response - ", response)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw FSQAPIRequestError.itemsNotFound }
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Response.self, from: data)
            //print("FSQAPIRequest Decode - ", decoded)
            return decoded
        } catch {
            //print("FSQAPIRequest Error - ", error)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        return decoded
    }
}
