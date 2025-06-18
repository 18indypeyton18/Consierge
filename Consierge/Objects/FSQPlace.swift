//
//  FSQPlace.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/19/24.
//

import Foundation

final class FSQPlace: Codable, Place {
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
    var version: Int = 1
    var status: String?
    var rating: Double?
    var popularity: Double?
    var cityLookup: [String:City]
    var photoURLs: [String] = []
    var placeTypeID: Int? = nil
    
    required init(fsq_id: String, name: String, description: String?, categories: [FSQCategory]?, location: FSQLocation, photos: [FSQPhotos]?, website: String, price: Int, geocodes: FSQGeocodes, rating: Double?, popularity: Double?) {
        self.cityLookup = ["Indianapolis":City(cityID: 1, name: "Indianapolis", nickname: "Indy", imageURL: "/Concierge/photos/cityHeaders/Indy.jpg", latitude: 39.7684, longitude: -86.1581, n: 40.48343, w: -86.99053, s: 39.1198, e: -85.7417), "Chicago":City(cityID: 2, name: "Chicago", nickname: "Chitown", imageURL: "/Concierge/photos/cityHeaders/Chicago.jpg", latitude: 41.8781, longitude: -87.6298, n: 42.28144, w: -88.40759, s: 41.44728, e: -87.43568), "":City(cityID: 0, name: "Chicago", nickname: "Chitown", imageURL: "/Concierge/photos/cityHeaders/Chicago.jpg", latitude: 41.8781, longitude: -87.6298, n: 42.28144, w: -88.40759, s: 41.44728, e: -87.43568)]
        
        self.id = 0
        self.name = name
        self.descr = description
        if let categories = categories, categories.isEmpty == false {
            self.genre = categories[0].name
        } else {
            self.genre = "Unknown"
        }
        if let neighborhood = location.neighborhood?[0] {
            self.neighborhood = neighborhood
        } else {
            self.neighborhood = "Unknown"
        }
        self.isLocal = true
        if let cityID = cityLookup[location.dma ?? ""] {
            self.cityID = cityID
        } else {
            self.cityID = City(cityID: 0, name: "Chicago", nickname: "Chitown", imageURL: "/Concierge/photos/cityHeaders/Chicago.jpg", latitude: 41.8781, longitude: -87.6298, n: 42.28144, w: -88.40759, s: 41.44728, e: -87.43568)
        }
        self.communityVotes = 0
        if let photos = photos, photos.isEmpty == false {
            self.imageURL = "\(photos[0].prefix)original\(photos[0].suffix)"
            for photo in photos {
                self.photoURLs.append("\(photo.prefix)original\(photo.suffix)")
            }
        } else if let categories = categories, categories.isEmpty == false {
            let category = categories[0]
            self.imageURL = "\(category.icon.prefix)120\(category.icon.suffix)"
        } else {
            self.imageURL = "https://ss3.4sqi.net/img/categories_v2/food/salad_120.png"
        }
        self.website = website
        self.address = location.formatted_address
        self.price = price
        self.latitude = geocodes.main.latitude
        self.longitude = geocodes.main.longitude
        self.fsqID = fsq_id
        self.rating = rating
        self.popularity = popularity
    }
    
    deinit {
        //print(name, "deinit")
    }
}


extension FSQPlace: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(lhs: FSQPlace, rhs: FSQPlace) -> Bool {
        return lhs.fsqID == rhs.fsqID
    }
}


struct FSQCategory: Codable {
    let id: Int
    let name: String
    let icon: FSQIcon
}

struct FSQIcon: Codable {
    let prefix: String
    let suffix: String
}

struct FSQLocation: Codable {
    let address: String?
    let census_block: String?
    let country: String
    let cross_street: String?
    let dma: String?
    let formatted_address: String
    let locality: String
    let postcode: String
    let neighborhood: [String]?
    let region: String
}

struct FSQPhotos: Codable {
    let id: String
    let created_at: String
    let prefix: String
    let suffix: String
    let width: Int
    let height: Int
    let classifications: [String]?
}

struct FSQGeocodes: Codable {
    let main: FSQCoordinate
    let roof: FSQCoordinate?
    let front_door: FSQCoordinate?
    let road: FSQCoordinate?
}
struct FSQCoordinate: Codable {
    let latitude: Double
    let longitude: Double
}



struct FSQDecoderParent: Codable {
    var results: [FSQDecoder]
}

struct FSQDecoder: Codable {
    let fsq_id: String
    let name: String
    let description: String?
    let categories: [FSQCategory]
    let location: FSQLocation
    let photos: [FSQPhotos]?
    let website: String?
    var price: Int?
    let geocodes: FSQGeocodes
    let rating: Double?
    let popularity: Double?
}

extension FSQDecoder {
    func placeify() -> FSQPlace {
        return FSQPlace(fsq_id: fsq_id, name: name, description: description, categories: categories, location: location, photos: photos, website: website ?? "https://google.com", price: price ?? 1, geocodes: geocodes, rating: rating, popularity: popularity)
    }
}
