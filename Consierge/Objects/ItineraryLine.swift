//
//  ItineraryLine.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import Foundation

struct ItineraryLine: Codable, Hashable, Equatable, Comparable {
    var ID: Int
    var itineraryID: Int
    var placeID: Int
    var fsqID: String
    var placeName: String
    var type: String
    var startDate: String?
    var customNote: String
    
    var startDateDate: Date? {
        guard let startDate = startDate else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: startDate) {
          return date
        }
        return nil
    }
    
    static func == (lhs: ItineraryLine, rhs: ItineraryLine) -> Bool {
        return lhs.ID == rhs.ID
    }
    
    static func < (lhs: ItineraryLine, rhs: ItineraryLine) -> Bool {
        if let lhsDate = lhs.startDate {
            if let rhsDate = rhs.startDate {
                if rhsDate == lhsDate {
                    return lhs.placeName.uppercased() > rhs.placeName.uppercased()
                } else {
                    return lhsDate > rhsDate
                }
            } else {
                return false
            }
        } else {
            if let _ = rhs.startDate {
                return true
            } else {
                return lhs.placeName.uppercased() > rhs.placeName.uppercased()
            }
        }
    }
}
