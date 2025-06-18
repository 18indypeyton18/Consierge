//
//  UserDefaultFuncitons.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//
import Foundation
let userLovedPlacesGroup = DispatchGroup()
let getuserGroup = DispatchGroup()
var lovedPlaceDict = [String:LovePlace]()
var recencyDict = [String:Int]()
var fetchedFSQPlaces = [String:Place]()

class UserDefaultFunctions {
    
    
    var userLovedPlacesRequestTask: Task<Void,Never>? = nil
    var getUserRequestTask: Task<Void,Never>? = nil
    deinit {
        userLovedPlacesRequestTask?.cancel()
        getUserRequestTask?.cancel()
    }
    
    func getLoggedInUser(userEmail: String) {
        getuserGroup.enter()
        getUserRequestTask = Task {
            if let user = try? await UserCheckRequest(userEmail: userEmail).send() {
                currentUser = user
            } else {
                currentUser = defaultUser
            }
            getuserGroup.leave()
            getUserRequestTask = nil
        }
        getuserGroup.wait()
    }
    
    func getUserLovedPlaces(currentUserID: Int) {
        userLovedPlaces = []
        recencyDict = [:]
        lovedPlaceDict = [:]
        userLovedPlacesGroup.enter()
        userLovedPlacesRequestTask = Task {
            //Get all userPlacesLoved and set defaults
            if let userPlacesLoved = try? await UserPlacesLovedRequest(userID: currentUserID).send() {
                userLovedPlaces += userPlacesLoved
                for place in userPlacesLoved {
                    UserDefaults.standard.set(true, forKey: "Concierge\(place.id)")
                }
            }
            
            if let userLovedPlaces = try? await UserLovedPlacesRequest(userID: currentUserID).send() {
                
                for userLovedPlace in userLovedPlaces {
                    if userLovedPlace.type == "Concierge" {
                        recencyDict[String(userLovedPlace.placeID)] = userLovedPlace.ID
                        lovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    } else {
                        recencyDict[userLovedPlace.fsqID] = userLovedPlace.ID
                        lovedPlaceDict[userLovedPlace.fsqID] = userLovedPlace
                    }
                }
            }
            
            if let userFSQsLoved = try? await UserFSQsLovedRequest(userID: currentUserID).send() {
                for userLovedPlace in userFSQsLoved {
                    if userLovedPlace.type == "Concierge" {
                        recencyDict[String(userLovedPlace.placeID)] = userLovedPlace.ID
                        lovedPlaceDict["\(userLovedPlace.placeID)"] = userLovedPlace
                    } else {
                        recencyDict[userLovedPlace.fsqID] = userLovedPlace.ID
                        lovedPlaceDict[userLovedPlace.fsqID] = userLovedPlace
                    }
                }
            }
            
            sortUserPlaces()
            userLovedPlacesGroup.leave()
        }
    }
    func sortUserPlaces() {
        userLovedPlaces = userLovedPlaces.sorted(by: { lhs, rhs in
            switch (lhs,rhs) {
            case (is ConciergePlace, is ConciergePlace):
                if let lhsRecency = recencyDict[String(lhs.id)], let rhsRecency = recencyDict[String(rhs.id)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (_, is ConciergePlace):
                if let lhsRecency = recencyDict[lhs.fsqID ?? ""], let rhsRecency = recencyDict[String(rhs.id)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (is ConciergePlace, _):
                if let lhsRecency = recencyDict[String(lhs.id)], let rhsRecency = recencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            default:
                if let lhsRecency = recencyDict[lhs.fsqID ?? ""], let rhsRecency = recencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            }
        })
    }
}
