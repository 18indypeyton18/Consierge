//
//  Comment.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/28/24.
//
import Foundation

struct Comment: Codable {
    var ID: Int
    var username: String
    var commentDate: String
    var comment: String
    var placeID: Int
    var fsqID: String?
    var placeType: String
    var communityScore: Int
    var status: String
    
    var commentDateDate: Date? {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: commentDate) {
          return date
        }
        return nil
    }
}

struct CommentUpvote: Codable {
    let userID: Int
    let commentID: Int
    let type: String
    let value: String
}

struct CommentStatus: Codable {
    let commentId: Int
    let status: String
}


struct PlaceStatus: Codable {
    let placeId: Int
    let status: String
}
