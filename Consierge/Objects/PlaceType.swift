//
//  PlaceType.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/2/24.
//

var allPlaceTypes = [Int:PlaceType]()

import Foundation

struct PlaceType: Codable, Equatable {
    let id: Int
    let name: String
    let iconName: String
    let clicked: Int
    var fsqCategoryCode: String
}

extension PlaceType: Comparable {
    static func < (lhs: PlaceType, rhs: PlaceType) -> Bool {
        return lhs.clicked > rhs.clicked
    }
}

