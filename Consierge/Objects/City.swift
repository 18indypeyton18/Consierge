//
//  City.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import UIKit

struct City {
    let cityID: Int
    let name: String
    let nickname: String
    var imageURL: String
    let latitude: Double
    let longitude: Double
    let n: Double
    let w: Double
    let s: Double
    let e: Double
    var status: String?
}

extension City: Codable {
}

extension City: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.cityID == rhs.cityID
    }
}


struct BaseCity: Codable {
    let userID: Int
    let cityID: Int
}

struct CityImgUpdate: Codable {
    let cityID: Int
    let headerImageURL: String
}
