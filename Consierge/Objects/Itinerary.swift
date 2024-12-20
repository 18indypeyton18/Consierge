//
//  Itinerary.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import Foundation


struct Itinerary: Codable, Hashable, Comparable {
    var ID: Int
    var userID: Int
    var status: String
    var createdDate: String
    var closedDate: String? = nil
    var name: String
    var cityID: Int?
    var coverImageURL: String?
    
    var createdDateDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = dateFormatter.date(from: createdDate) {
          return date
        }
        return nil
    }
    
    static func <(lhs: Itinerary, rhs: Itinerary) -> Bool {
        if let lhsDate = lhs.createdDateDate, let rhsDate = rhs.createdDateDate {
            return lhsDate < rhsDate
        } else {
            return lhs.ID < rhs.ID
        }
    }
    
    static func == (lhs: Itinerary, rhs: Itinerary) -> Bool {
        return lhs.ID == rhs.ID
    }
}



struct ItineraryWithLine: Codable {
    var itinerary: Itinerary
    var itineraryLine: ItineraryLine
}
