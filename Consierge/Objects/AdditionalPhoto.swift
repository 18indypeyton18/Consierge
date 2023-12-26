//
//  AdditionalPhoto.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/10/24.
//

import Foundation

struct AdditionalPhoto: Codable {
    let placeID: Int
    let path: String
    let photoIndex: Int
    var status: String?
}
