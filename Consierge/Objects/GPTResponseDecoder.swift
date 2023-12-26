//
//  GPTResponseDecoder.swift
//  Consierge
//
//  Created by Austin McLaughlin on 10/6/24.
//

import Foundation

struct GPTPromptsResponse: Decodable {
    let suggestedPrompts: [Prompt]
}

struct Prompt: Decodable {
    let prompt: String
}

struct GPTPlacesResponse: Decodable {
    let suggestedPlaces: [GPTPlace]
    let location: GPTLocation?
}

class GPTPlace: Decodable {
    var name: String
    var address: String
    var website: String
    
    init(name: String, address: String, website: String) {
        self.name = name
        self.address = address
        self.website = website
    }
}

class GPTLocation: Decodable {
    var cityName: String
    var cityCenterLatitude: Double
    var cityCenterLongitude: Double
    
    init(cityName: String, cityCenterLatitude: Double, cityCenterLongitude: Double) {
        self.cityName = cityName
        self.cityCenterLatitude = cityCenterLatitude
        self.cityCenterLongitude = cityCenterLongitude
    }
}
