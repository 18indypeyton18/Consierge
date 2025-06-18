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
    let placeTypeID: Int
}

struct ApproveTag: Codable {
    let tagID: Int
    let tagName: String
    let userID: Int
    let placeID: Int
    let cityID: Int
    let placeTypeID: Int
    let status: String
    
    init(addTag: AddTag, status: String) {
        self.tagID = addTag.tagID
        self.tagName = addTag.tagName
        self.userID = addTag.userID
        self.placeID = addTag.placeID
        self.cityID = addTag.cityID
        self.placeTypeID = addTag.placeTypeID
        self.status = status
    }
}

struct ReviewTag: Codable {
    let tagID: Int
    let tagName: String
    let userID: Int
    let placeID: Int
    let cityID: Int
    let placeTypeID: Int
    var status: String
}
