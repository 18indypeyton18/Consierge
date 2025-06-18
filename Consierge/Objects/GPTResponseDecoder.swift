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


class GPTSuggestedConciergePlace: Decodable {
    var placeName: String
    var address: String
    var city: City
    var placeType: String
    var website: String
    var category: String
    var neighborhood: String
    var suggestedDescr: String
    var price: Int
    var latitude: Double
    var longitude: Double
    var isLocal: Bool
    var phoneNumber: String?
    var menuURL: String?
    
        
    init(placeName: String, address: String, city: City, placeType: String, website: String, category: String, neighborhood: String, suggestedDescr: String, price: Int, latitude: Double, longitude: Double, isLocal: Bool, phoneNumber: String?, menuURL: String?) {
        self.placeName = placeName
        self.address = address
        self.city = city
        self.placeType = placeType
        self.website = website
        self.category = category
        self.neighborhood = neighborhood
        self.suggestedDescr = suggestedDescr
        self.price = price
        self.latitude = latitude
        self.longitude = longitude
        self.isLocal = isLocal
        self.phoneNumber = phoneNumber
        self.menuURL = menuURL
    }
}

struct GPTModerationResponse: Decodable {
    let moderationResult: String
}
