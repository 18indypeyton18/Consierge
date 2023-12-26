//
//  GoogleAPIRequest.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/22/24.
//

import Foundation
import UIKit

//Sets up the APIRequest framework and works with APIService to handle all network calls throughout the app

//create protocol that all APIServices will use and determine initial variables
protocol GooglePlacesAPIRequest {
    associatedtype Response
    
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var request: URLRequest { get }
}

//default the host name & port
extension GooglePlacesAPIRequest {
    var host: String { "maps.googleapis.com" }
    var port: Int { 443 }
}

//set up optional values QueryItems (Get) and PostData (Post)
extension GooglePlacesAPIRequest {
    var queryItems: [URLQueryItem]? { nil }
}

//construct URLRequest variable with the URLComponents scheme, host, port, path, queryItems, postData?
extension GooglePlacesAPIRequest {
    var request: URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.port = port
        components.path = path
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        //request.setValue("application/json", forHTTPHeaderField: "accept")
        
        return request
    }
}

enum GooglePlacesAPIRequestError: Error {
    case itemsNotFound
    case requestFailed
}

//Decodable meaning Custom Objects to be returned - for example CityRequest, RestaurantRequest, corresponding usually to one table in the DB
//get the data using the path specified in APIService and decode the response
//to debug uncomment print(response), print(decoded)
extension GooglePlacesAPIRequest where Response: Decodable {
    func send() async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        
        //print("GoogleAPIRequest Response - ", response)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw FSQAPIRequestError.itemsNotFound }
        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Response.self, from: data)
            //print("GoogleAPIRequest Decode - ", decoded)
            return decoded
        } catch {
            //print("GoogleAPIRequest Error - ", error)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Response.self, from: data)
        return decoded
    }
}

//get an image from the server using a specified Path from ImageRequest
extension GooglePlacesAPIRequest where Response == UIImage {
    func send() async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(for: request)
        //print(response)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { throw ImageRequestError.imageDataMissing }
        guard let image = UIImage(data: data) else { throw ImageRequestError.couldNotInitializeFromData }
        return image
    }
}
