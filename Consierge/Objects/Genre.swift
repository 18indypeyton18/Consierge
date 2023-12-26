//
//  Genre.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/19/24.
//

import Foundation

struct Genre {
    var ID: Int
    var name: String
    var placeTypeID: Int
    var clicked: Int
    var fsqCategoryCode: Int
}

extension Genre: Codable { }

extension Genre: Comparable {
    static func < (lhs: Genre, rhs: Genre) -> Bool {
        return lhs.clicked > rhs.clicked
    }
}
