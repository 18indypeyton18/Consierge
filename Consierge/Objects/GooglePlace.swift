//
//  GooglePlace.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/22/24.
//

import Foundation

final class GooglePlace: Place {
    var cityLookup: [String: City] = ["Indianapolis":City(cityID: 1, name: "Indianapolis", nickname: "Indy", imageURL: "/Concierge/photos/cityHeaders/Indy.jpg", latitude: 39.7684, longitude: -86.1581, n: 40.48343, w: -86.99053, s: 39.1198, e: -85.7417), "Chicago":City(cityID: 2, name: "Chicago", nickname: "Chitown", imageURL: "/Concierge/photos/cityHeaders/Chicago.jpg", latitude: 41.8781, longitude: -87.6298, n: 42.28144, w: -88.40759, s: 41.44728, e: -87.43568)]
    
    var id: Int
    var name: String
    var descr: String?
    var genre: String
    var neighborhood: String
    var isLocal: Bool
    var cityID: City
    var communityVotes: Int
    var imageURL: String
    var website: String
    var address: String
    var price: Int
    var latitude: Double
    var longitude: Double
    var fsqID: String?
    var specialCategory: String?
    var version: Int
    var photoURLs: [String] = []
    var rating: Double?
    var placeTypeID: Int? = nil
    
    required init(placeID: String, name: String, editorial_summary: GooglePlaceEditorialSummary, formatted_address: String, types: [String], website: String, address_components: [GoogleAddressComponent], geometry: GooglePlaceGeometry, photos: [GooglePlacePhoto], price_level: Int, rating: Double?) {
        self.id = 0
        self.name = name
        self.descr = editorial_summary.overview
        self.genre = types[0]
        self.neighborhood = address_components[2].long_name
        self.isLocal = true
        if let cityID = cityLookup[address_components[3].long_name] {
            self.cityID = cityID
        } else {
            self.cityID = City(cityID: 2, name: "Chicago", nickname: "Chitown", imageURL: "/Concierge/photos/cityHeaders/Chicago.jpg", latitude: 41.8781, longitude: -87.6298, n: 42.28144, w: -88.40759, s: 41.44728, e: -87.43568)
        }
        self.communityVotes = 0
        self.imageURL = photos[0].photo_reference
        for photo in photos {
            self.photoURLs.append(photo.photo_reference)
        }
        self.website = website
        self.address = formatted_address
        self.price = price_level
        self.latitude = geometry.location.lat
        self.longitude = geometry.location.lng
        self.fsqID = placeID
        self.version = 0
        self.rating = rating
    }
    
    deinit {
        //print(name, "deinit")
    }
}

extension GooglePlace: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(lhs: GooglePlace, rhs: GooglePlace) -> Bool {
        return lhs.fsqID == rhs.fsqID
    }
}


extension GooglePlace: Comparable {
    static func < (lhs: GooglePlace, rhs: GooglePlace) -> Bool{
        return lhs.name > rhs.name
    }
}


struct GooglePlaceDecoderParent: Codable {
    let result: GooglePlaceDecoder
}

struct GooglePlaceDecoder: Codable {
    let place_id: String
    let name: String
    let editorial_summary: GooglePlaceEditorialSummary
    let formatted_address: String
    let types: [String]
    let website: String
    let address_components: [GoogleAddressComponent]
    let geometry: GooglePlaceGeometry
    let photos: [GooglePlacePhoto]
    let price_level: Int
    let rating: Double?
    
    func placeify() -> GooglePlace {
        return GooglePlace(placeID: place_id, name: name, editorial_summary: editorial_summary, formatted_address: formatted_address, types: types, website: website, address_components: address_components, geometry: geometry, photos: photos, price_level: price_level, rating: rating)
    }
}

struct GooglePlaceEditorialSummary: Codable {
    let overview: String
}

struct GoogleAddressComponent: Codable {
    let long_name: String
    let short_name: String
    let types: [String]
}

struct GooglePlaceGeometry: Codable {
    let location: GooglePlaceLocation
}

struct GooglePlaceLocation: Codable {
    let lat: Double
    let lng: Double
}

struct GooglePlacePhoto: Codable {
    let height: Int
    let photo_reference: String
    let width: Int
}


struct GooglePlaceFindDecoder: Codable {
    let error_message: String?
    let candidates: [GooglePlaceFindCandidate]
    let status: String
}

struct GooglePlaceFindCandidate: Codable {
    let place_id: String
}

struct GoogleCandidatePlacesDecoder: Codable {
    let results: [GooglePlaceFindCandidate]
}
