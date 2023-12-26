//
//  Neighborhood.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/19/24.
//

import Foundation

struct Neighborhood {
    var ID: Int
    var cityID: Int
    var name: String
    var clicked: Int
}

extension Neighborhood: Codable { }

extension Neighborhood: Comparable {
    static func < (lhs: Neighborhood, rhs: Neighborhood) -> Bool {
        return lhs.clicked > rhs.clicked
    }
}
