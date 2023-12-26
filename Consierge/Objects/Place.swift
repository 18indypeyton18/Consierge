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
