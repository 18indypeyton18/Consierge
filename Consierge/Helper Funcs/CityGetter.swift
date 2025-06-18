//
//  CityGetter.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/28/23.
//

import Foundation

class CityGetter {
    
    var cities = [City]()
    var baseCity: City? = nil
    
    let cityDispatch = DispatchGroup()
    var citiesRequestTask: Task<Void, Never>? = nil
    var baseCitiesRequestTask: Task<Void, Never>? = nil
    deinit {
        citiesRequestTask?.cancel()
        baseCitiesRequestTask?.cancel()
    }
    
    func getCities() {
        cityDispatch.enter()
        //fetch all cities from the DB, including name, nickname, headerImageURL
        citiesRequestTask?.cancel()
        citiesRequestTask = Task {
            if let cities = try? await CityRequest().send() {
                self.cities = cities
            } else {
                self.cities = []
            }
            cityDispatch.leave()
            citiesRequestTask = nil
        }
    }
    
    func returnCities() -> [City] {
        getCities()
        cityDispatch.wait()
        return self.cities
    }
    
    func getUserBaseCity() -> City? {
        let currentUserID = currentUser.id
        cityDispatch.enter()
        baseCitiesRequestTask = Task {
            if let cities = try? await GetBaseCityRequest(userID: currentUserID).send() {
                self.baseCity = cities[0]
            }
            cityDispatch.leave()
            baseCitiesRequestTask = nil
        }
        cityDispatch.wait()
        return self.baseCity
    }
    
    func getClosestCity(user: User) -> City? {
        getCities()
        cityDispatch.wait()
        
        var minDistance = 10000.0
        var retCity: City? = nil
        if let userLat = user.latitude, let userLon = user.longitude {
            for city in cities {
                let latDif = (userLat) - city.latitude
                let lonDif = (userLon) - city.longitude
                if abs(latDif * lonDif) < minDistance {
                    retCity = city
                    minDistance = abs(latDif * lonDif)
                }
            }
        }
        setUserBaseCity(baseCity: BaseCity(userID: user.id, cityID: retCity?.cityID ?? -1))
        return retCity
    }
    
    func setUserBaseCity(baseCity: BaseCity) {
        Task {
            if let resultValue = try? await BaseCityRequest(baseCity: baseCity).send(), resultValue["status"] == "Success" {
            } else {
                // print("set base city api failure")
            }
        }
    }
}
