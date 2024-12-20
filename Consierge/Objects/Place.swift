//
//  Place.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/10/24.
//

import Foundation

protocol Place: AnyObject {
    var id: Int { get }
    var name: String { get set }
    var descr: String? { get set }
    var genre: String { get set }
    var neighborhood: String { get set }
    var isLocal: Bool { get set }
    var cityID: City { get }
    var communityVotes: Int { get set }
    var imageURL: String { get set }
    var website: String { get set }
    var address: String { get set }
    var price: Int { get set }
    var latitude: Double { get set }
    var longitude: Double { get set }
    var fsqID: String? { get }
    var specialCategory: String? { get }
    var version: Int { get set }
    var placeTypeID: Int? { get }
}

final class ConciergePlace: Codable, Place {
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
    var placeTypeID: Int?
    
    init(id: Int, name: String, descr: String?, genre: String, neighborhood: String, isLocal: Bool, cityID: City, communityVotes: Int, imageURL: String, website: String, address: String, price: Int, latitude: Double, longitude: Double, fsqID: String?, specialCategory: String?, version: Int, status: String?, placeTypeID: Int?) {
        self.id = id
        self.name = name
        self.descr = descr
        self.genre = genre
        self.neighborhood = neighborhood
        self.isLocal = isLocal
        self.cityID = cityID
        self.communityVotes = communityVotes
        self.imageURL = imageURL
        self.website = website
        self.address = address
        self.price = price
        self.latitude = latitude
        self.longitude = longitude
        self.fsqID = fsqID
        self.specialCategory = specialCategory
        self.version = version
        self.status = status
        self.placeTypeID = placeTypeID
    }
}

extension ConciergePlace: CustomStringConvertible {
    var description: String {
        return "{'id': '\(id)', 'name': '\(name)', 'desc': '\(descr ?? "")', 'genre': '\(genre)', 'neighborhood': '\(neighborhood)', 'isLocal': '\(isLocal)', 'cityID': '\(cityID)', 'communityVotes': '\(communityVotes)', 'imageURL': '\(imageURL)', 'website': '\(website)', 'address': '\(address)', 'price': '\(price)', 'latitude': '\(latitude)', 'longitude': '\(longitude)', 'fsqID': '\(fsqID ?? "")', 'specialCategory': '\(specialCategory ?? ""), 'version': '\(version), 'status': '\(status ?? ""), 'placeTypeID': '\(placeTypeID)'}"
    }
}

extension ConciergePlace: Comparable {
    static func < (lhs: ConciergePlace, rhs: ConciergePlace) -> Bool {
        return lhs.communityVotes < rhs.communityVotes
    }
}

extension ConciergePlace: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func ==(lhs: ConciergePlace, rhs: ConciergePlace) -> Bool {
        print("LHS PLACE == RHS Place", lhs.id, rhs.id)
        return lhs.id == rhs.id
    }
}
