//
//  UserDefaultFuncitons.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//
import Foundation
let userLovedPlacesGroup = DispatchGroup()
let getuserGroup = DispatchGroup()
var lovedFSQPlaces = [LovePlace]()
var lovedPlaceDict = [String:LovePlace]()

class UserDefaultFunctions {
    var recencyDict = [String:Int]()
    
    
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
        userLovedPlacesGroup.enter()
        userLovedPlacesRequestTask = Task {
            //Get all userPlacesLoved and set defaults
            if let userPlacesLoved = try? await UserPlacesLovedRequest(userID: currentUserID).send() {
                userLovedPlaces += userPlacesLoved
                for place in userPlacesLoved {
                    UserDefaults.standard.set(true, forKey: "Concierge\(place.id)")
                }
            }
            if let userFSQsLoved = try? await UserFSQsLovedRequest(userID: currentUserID).send() {
                for fsqLovePlace in userFSQsLoved {
                    UserDefaults.standard.set(true, forKey: "fsqPlace\(fsqLovePlace.fsqID)")
                    //currentUserPlacesLoved?.append(fsqLovePlace)
                    
                    if let lovedPlaces = try? await UserFSQsLovedRequest(userID: currentUserID).send() {
                        lovedFSQPlaces = lovedPlaces
                    }
                }}
            /*if let userGooglysLoved = try? await UserGooglysLovedRequest(userID: currentUserID).send() {
                for googlyLovePlace in userGooglysLoved {
                    UserDefaults.standard.set(true, forKey: "fsqPlace\(googlyLovePlace.fsqID)")
                    //currentUserPlacesLoved?.append(fsqLovePlace)
                    
                    if let googleParent = try? await GooglePlaceDetailRequest(placeID: googlyLovePlace.fsqID).send() {
                        let googlePlace = googleParent.result
                        let place = googlePlace.placeify()
                        userLovedPlaces.append(place)
                    }
                }}*/
            if let userLovedPlaces = try? await UserLovedPlacesRequest(userID: currentUserID).send() {
                
                for userLovedPlace in userLovedPlaces {
                    if userLovedPlace.fsqID == "" {
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
            if let lhsRecency = recencyDict[String(lhs.id)], let rhsRecency = recencyDict[String(rhs.id)] {
                return lhsRecency > rhsRecency
            } else {
                return lhs.name < rhs.name
            }
            /*
            switch (lhs,rhs) {
            case (is FSQPlace, is FSQPlace):
                if let lhsRecency = recencyDict[lhs.fsqID ?? ""], let rhsRecency = recencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (_, is FSQPlace):
                if let lhsRecency = recencyDict[String(lhs.ID)], let rhsRecency = recencyDict[rhs.fsqID ?? ""] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            case (is FSQPlace, _):
                if let lhsRecency = recencyDict[lhs.fsqID ?? ""], let rhsRecency = recencyDict[String(rhs.ID)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            default:
                if let lhsRecency = recencyDict[String(lhs.ID)], let rhsRecency = recencyDict[String(rhs.ID)] {
                    return lhsRecency > rhsRecency
                } else {
                    return lhs.name < rhs.name
                }
            }*/
        })
    }
}
