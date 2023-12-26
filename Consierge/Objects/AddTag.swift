//
//  AddTag.swift
//  Consierge
//
//  Created by Austin McLaughlin on 9/21/24.
//

import Foundation

struct AddTag: Codable {
    let tagID: Int
    let tagName: String
    let userID: Int
    let placeID: Int
    let cityID: Int
}
