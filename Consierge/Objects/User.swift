//
//  User.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import Foundation

struct User: Codable {
    var id: Int
    var firstName: String
    var lastName: String
    var email: String
    var latitude: Double?
    var longitude: Double?
    var password: String
    var username: String?
    var profPicImageURL: String?
    var role: String
    var userIdentifier: String?
}


struct ProfilePic: Codable {
    var imageURL: String
    var userID: Int
}
