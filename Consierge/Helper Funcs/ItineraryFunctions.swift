//
//  ItineraryFunctions.swift
//  Consierge
//
//  Created by Austin McLaughlin on 2/16/25.
//

import Foundation


var itineraries = [Itinerary]()
var itineraryLinesDict = [Int: [ItineraryLine]]()
var itineraryAdded = false


class ItineraryFunctions {
    weak var delegate: ItineraryFunctionsDelegate?
    var group = DispatchGroup()
    
    var itinerariesRequestTask: Task<Void, Never>? = nil
    var itineraryLinesRequestTask: Task<Void, Never>? = nil
    deinit {
        itinerariesRequestTask?.cancel()
        itineraryLinesRequestTask?.cancel()
    }
    
    func getItineraries() {
        let userID = currentUser.id
        itinerariesRequestTask?.cancel()
        itinerariesRequestTask = Task {
            if let userItineraries = try? await UserItinerariesRequest(userID: userID).send() {
                for itinerary in userItineraries {
                    group.enter()
                    getItineraryLines(itineraryId: itinerary.ID)
                }
                group.notify(queue: .main) {
                    itineraries = userItineraries
                    self.delegate?.updatePage()
                }
            } else {
                itineraries = []
                delegate?.updatePage()
            }
            itinerariesRequestTask = nil
        }
    }
    
    func getItineraryLines(itineraryId: Int) {
        itineraryLinesRequestTask = Task {
            if let itineraryLines = try? await UserItineraryLinesRequest(itineraryID: itineraryId).send() {
                DispatchQueue.main.async {
                    itineraryLinesDict[itineraryId] = itineraryLines
                }
            } else {
                itineraryLinesDict[itineraryId] = []
            }
            group.leave()
            itineraryLinesRequestTask = nil
        }
    }
    
    func addItinerary(newItinerary: ItineraryWithLine, isNewItinerary: Bool) {
        itineraryAdded = true
        Task {
            //if new Itinerary run BrandNew API
            //if existing Itinerary run NewLine API
            if isNewItinerary {
                let resultValue = try? await BrandNewItineraryRequest(itinerary: newItinerary).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        itineraries.append(newItinerary.itinerary)
                        itineraryLinesDict[newItinerary.itinerary.ID] = [newItinerary.itineraryLine]
                        delegate?.updatePage()
                    } else {
                        // print(resultValue)
                    }
                } else {
                    // print("error")
                }
            } else {
                let resultValue = try? await NewItineraryLineRequest(itinerary: newItinerary).send()
                if let resultValue = resultValue {
                    if resultValue["status"] == "Success" {
                        guard var itLines = itineraryLinesDict[newItinerary.itinerary.ID] else {
                            delegate?.updatePage(); return;
                        }
                        itLines.append(newItinerary.itineraryLine)
                        itineraryLinesDict[newItinerary.itinerary.ID] = itLines
                        delegate?.updatePage()
                    } else {
                        // print(resultValue)
                    }
                } else {
                    // print("error")
                }
            }
        }
    }
}

protocol ItineraryFunctionsDelegate: AnyObject {
    func updatePage()
}
