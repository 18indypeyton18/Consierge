//
//  LovePlaceFunctions.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/10/24.
//

import Foundation

var userLovedPlaces = [Place]()
var placeRecentlyLoved = false

class LovePlaceFunctions {
    weak var delegate: LovePlaceDelegate?
    let group = DispatchGroup()
    
    func lovePlace(place: Place?, placeSource: PlaceSource) {
        placeRecentlyLoved = true
        guard let place = place else {return}
        let userID = currentUser.id
        
        let midnightToday = Date()
        let dateString = midnightToday.ISO8601Format()
        
        let lovePlace = LovePlace(ID: 0, userID: userID, placeID: place.id, type: placeSource.rawValue, lovedDate: dateString, fsqID: "", placeTypeID: place.placeTypeID ?? 0, cityID: place.cityID.cityID)
        
        let placeLoved = userLovedPlaces.contains { thisPlace in
            if let place = place as? ConciergePlace, let thisPlace = thisPlace as? ConciergePlace {
                return thisPlace == place
            } else {
                return false
            }
        }
        
        group.enter()
        if placeLoved{
            Task {
                let resultValue = try? await unLovePlaceRequeset(lovePlace:lovePlace).send()
                if resultValue?["status"] == "Success" {
                    let placeIndex = getPlaceIndex(place:place)
                    guard let placeIndex = placeIndex else {
                        group.leave()
                        return
                    }
                    userLovedPlaces.remove(at: placeIndex)
                    lovedPlaceDict.removeValue(forKey: "\(place.id)")
                    UserDefaults.standard.set(false, forKey: "\(placeSource.rawValue)\(place.id)")
                }
                group.leave()
            }
        } else {
            Task {
                let resultValue = try? await lovePlaceRequeset(lovePlace: lovePlace).send()
                if resultValue?["status"] == "Success" {
                    userLovedPlaces.insert(place, at: 0)
                    lovedPlaceDict["\(lovePlace.placeID)"] = lovePlace
                    UserDefaults.standard.set(true, forKey: "\(placeSource.rawValue)\(place.id)")
                }
                group.leave()
            }
        }
        group.wait()
    }
    
    func getPlaceIndex(place: Place) -> Int? {
        var placeIndex: Int = -1
        
        if let place = place as? ConciergePlace {
            placeIndex = userLovedPlaces.firstIndex { $0 as? ConciergePlace == place } ?? -1
        } else if let place = place as? FSQPlace {
            placeIndex = userLovedPlaces.firstIndex { $0.fsqID == place.fsqID } ?? -1
        }
        
        if placeIndex == -1 {
            return nil
        } else {
            return placeIndex
        }
    }
}

extension LovePlaceFunctions {
    func loveFSQPlace(place: Place?, placeSource: PlaceSource, placeTypeID: Int, cityID: Int) {
        placeRecentlyLoved = true
        guard let place = place else {return}
        let userID = currentUser.id
        
        let midnightToday = Date()
        let dateString = midnightToday.ISO8601Format()
        
        let lovePlace = LovePlace(ID: 0, userID: userID, placeID: 0, type: placeSource.rawValue, lovedDate: dateString, fsqID: place.fsqID ?? "", placeTypeID: placeTypeID, cityID: cityID)
        
        let placeLoved = userLovedPlaces.contains { lp in
            lp.fsqID == place.fsqID
        }
        
        group.enter()
        if placeLoved{
            Task {
                let resultValue = try? await unLovePlaceRequeset(lovePlace:lovePlace).send()
                if resultValue?["status"] == "Success" {
                    let placeIndex = getPlaceIndex(place:place)
                    guard let placeIndex = placeIndex else {
                        group.leave()
                        return
                    }
                    userLovedPlaces.remove(at: placeIndex)
                    lovedPlaceDict.removeValue(forKey: "\(place.fsqID ?? "")")
                    UserDefaults.standard.set(false, forKey: "\(placeSource.rawValue)\(place.fsqID ?? "")")
                }
                group.leave()
            }
            UserDefaults.standard.set(false, forKey: "\(placeSource.rawValue)\(place.id)")
        } else {
            Task {
                let resultValue = try? await lovePlaceRequeset(lovePlace: lovePlace).send()
                if resultValue?["status"] == "Success" {
                    userLovedPlaces.insert(place, at: 0)
                    lovedPlaceDict["\(lovePlace.fsqID)"] = lovePlace
                    UserDefaults.standard.set(true, forKey: "\(placeSource.rawValue)\(place.fsqID ?? "")")
                }
                group.leave()
            }
        }
        group.wait()
    }
}

protocol LovePlaceDelegate: AnyObject {
    func updatePage()
}
