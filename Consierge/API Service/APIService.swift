//
//  APIRequest.swift
//  Consierge
//
//  Created by Austin McLaughlin on 12/27/23.
//

import Foundation
import UIKit

//Definitions for different API Requests to the LAMP server hosted on AWS
//Each API Request will hit a different php script hosted on the server

//Authenticate user login
struct UserLoginRequest: APIRequest {
    typealias Response = User
    typealias IsImage =  Void
    
    var userEmail: String
    var userPass: String
    
    var path: String { "/Consierge/userLogin.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "email", value: userEmail), URLQueryItem(name: "pass", value: userPass)]
    }
}

//Register new user
struct NewUserRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var user: User
    
    var path: String { "/Consierge/userRegister.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(user)
    }
}

//Check if user email exists in the database already
struct UserCheckRequest: APIRequest {
    typealias Response = User
    typealias IsImage =  Void
    
    var userEmail: String
    
    var path: String { "/Consierge/userCheck.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "email", value: userEmail)]
    }
}

//Check if user email exists in the database already
struct AppleUserCheckRequest: APIRequest {
    typealias Response = User
    typealias IsImage =  Void
    
    var userIdentifier: String?
    
    var path: String { "/Consierge/appleUserCheck.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userIdentifier", value: userIdentifier)]
    }
}

struct UserResetPWRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var userEmail: String
    var resetPW: Bool
    
    var path: String { "/resetPW.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "email", value: userEmail), URLQueryItem(name: "resetPW", value: String(resetPW))]
    }
}

struct DeleteAccountRequest: APIRequest {
    typealias Response = [String: String]
    typealias IsImage  = Void

    let userID: String

    var path: String { "/Consierge/deleteAccount.php" }

    var postData: Data? {
        try? JSONEncoder().encode(["userID": userID])
    }
}

//return all cities in the DB
struct CityRequest: APIRequest {
    typealias Response = [City]
    typealias IsImage =  Void
        
    var path: String { "/Consierge/cities.php" }
}


//Get image from the server for a specified Image URL
struct ImageRequest: ImageAPIRequest {
    typealias Response = UIImage
    typealias IsImage =  Void
        
    var path: String
}

struct GetBaseCityRequest: APIRequest {
    typealias Response = [City]
    typealias IsImage =  Void
    
    var userID: Int?
    
    var path: String { "/Consierge/getDefaultCities.php" }
    
    var queryItems: [URLQueryItem]? {
        if let userID = userID {
            return [URLQueryItem(name: "userID", value: String(userID))]
        } else {
            return nil
        }
    }
}

//Send a 'Base' City to the DB for a specified user
struct BaseCityRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var baseCity: BaseCity
    
    var path: String { "/Consierge/baseCity.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(baseCity)
    }
}

struct PlaceTypesByCityRequest: APIRequest {
    typealias Response = [PlaceType]
    typealias IsImage =  Void
    
    var cityID: Int?
    
    var path: String { "/Consierge/placeTypesByCity.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "cityID", value: String(cityID ?? 0))]
    }
}

struct AllPlaceTypesRequest: APIRequest {
    typealias Response = [PlaceType]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/allPlaceTypes.php" }
}

//return all restaurants in the DB
struct GetPlacesRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var cityID: Int?
    var placeTypeID: Int?
    
    var path: String { "/Consierge/places.php" }
    
    var queryItems: [URLQueryItem]? {
        if let cityID = cityID, let placeTypeID = placeTypeID {
            return [URLQueryItem(name: "cityID", value: String(cityID)), URLQueryItem(name: "placeTypeID", value: String(placeTypeID))]
        } else {
            return nil
        }
    }
}

//Send a 'Loved' Place to the DB for a specified user
struct lovePlaceRequeset: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var lovePlace: LovePlace
    
    var path: String { "/Consierge/lovePlace.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(lovePlace)
    }
}

//Delete a 'Loved' Place from the DB
struct unLovePlaceRequeset: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var lovePlace: LovePlace
    
    var path: String { "/Consierge/unLovePlace.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(lovePlace)
    }
}

//get all restaurants a specified user has loved from the DB
struct UserPlacesLovedRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var userID: Int
    
    var path: String { "/Consierge/userPlacesLoved.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID))]
    }
}
//get all cafes a specified user has loved from the DB
struct UserLovedPlacesRequest: APIRequest {
    typealias Response = [LovePlace]
    typealias IsImage =  Void
    
    var userID: Int
    
    var path: String { "/Consierge/userLovedPlaces.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID))]
    }
}

struct UserFSQsLovedRequest: APIRequest {
    typealias Response = [LovePlace]
    typealias IsImage =  Void
    
    var userID: Int
    
    var path: String { "/Consierge/userFSQLovedPlaces.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID))]
    }
}


//get a single restaurant from ID
struct SinglePlaceRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var placeID: Int?
    
    var path: String { "/Consierge/singlePlace.php" }
    
    var queryItems: [URLQueryItem]? {
        if let placeID = placeID {
            return [URLQueryItem(name: "placeID", value: String(placeID))]
        } else {
            return nil
        }
    }
}

struct AddTagRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var addTag: AddTag
    
    var path: String { "/Consierge/addTag.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(addTag)
    }
}

struct ApproveTagRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var approveTag: ApproveTag
    
    var path: String { "/Consierge/approveTag.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(approveTag)
    }
}

struct UpdateCommentStatus: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var commentStatus: CommentStatus
    
    var path: String { "/Consierge/updateCommentStatus.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(commentStatus)
    }
}

struct UpdatePlaceStatus: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var placeStatus: PlaceStatus
    
    var path: String { "/Consierge/updatePlaceStatus.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(placeStatus)
    }
}

struct UpdatePlaceCoverStatus: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var placeStatus: PlaceStatus
    
    var path: String { "/Consierge/updatePlaceCoverStatus.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(placeStatus)
    }
}

struct UpdateCityImgURL: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var cityImgUpdate: CityImgUpdate
    
    var path: String { "/Consierge/updateCityImgURL.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(cityImgUpdate)
    }
}

struct PlaceTagsRequest: APIRequest {
    typealias Response = [PlaceTag]
    typealias IsImage =  Void
    
    var placeID: Int?
    
    var path: String { "/Consierge/placeTags.php" }
    
    var queryItems: [URLQueryItem]? {
        if let placeID = placeID {
            return [URLQueryItem(name: "placeID", value: String(placeID))]
        } else {
            return nil
        }
    }
}

struct CityTagsRequest: APIRequest {
    typealias Response = [PlaceTag]
    typealias IsImage =  Void
    
    var cityID: Int?
    var placeTypeID: Int?
    
    var path: String { "/Consierge/cityTags.php" }
    
    var queryItems: [URLQueryItem]? {
        if let cityID = cityID, let placeTypeID = placeTypeID {
            return [URLQueryItem(name: "cityID", value: String(cityID)), URLQueryItem(name: "placeTypeID", value: String(placeTypeID))]
        } else {
            return nil
        }
    }
}

struct GetSelectedTags: APIRequest {
    typealias Response = [AddTag]
    typealias IsImage =  Void
    
    var tag: String
    var city: Int
    
    var path: String { "/Consierge/selectedTags.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "city", value: String(city)), URLQueryItem(name: "tag", value: String(tag))]
    }
}

//return all neighborhoods in the DB
struct NeighborhoodRequest: APIRequest {
    typealias Response = [Neighborhood]
    typealias IsImage =  Void
    
    var cityID: Int?
    
    var path: String { "/Consierge/neighborhoods.php" }
    
    var queryItems: [URLQueryItem]? {
        if let cityID = cityID {
            return [URLQueryItem(name: "cityID", value: String(cityID))]
        } else {
            return nil
        }
    }
}

//return all genres in the DB
struct GenreRequest: APIRequest {
    typealias Response = [Genre]
    typealias IsImage =  Void
    
    var placeTypeID: Int?
        
    var path: String { "/Consierge/genres.php" }
    var queryItems: [URLQueryItem]? {
        if let placeTypeID = placeTypeID {
            return [URLQueryItem(name: "placeTypeID", value: String(placeTypeID))]
        } else {
            return nil
        }
    }
}

struct PlaceTypeClickedRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var placeTypeID: Int
    
    var path: String { "/Consierge/incrementPlaceTypeClicks.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "placeTypeID", value: String(placeTypeID))]
    }
}


struct NeighborhoodClickedRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var neighborhoodID: Int
    
    var path: String { "/Consierge/incrementNeighborhoodClicks.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "neighborhoodID", value: String(neighborhoodID))]
    }
}

struct GenreClickedRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var genreID: Int
    
    var path: String { "/Consierge/incrementGenreClicks.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "genreID", value: String(genreID))]
    }
}

struct TagClickedRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var tagName: String
    
    var path: String { "/Consierge/incrementTagClicks.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "tagName", value: String(tagName))]
    }
}

//Get all comments for a specified Place
struct CommentsRequest: APIRequest {
    typealias Response = [Comment]
    typealias IsImage =  Void
    
    var placeID: Int?
    var type: String?
    
    var path: String { "/Consierge/comments.php" }
    
    var queryItems: [URLQueryItem]? {
        if let placeID = placeID {
            return [URLQueryItem(name: "placeID", value: String(placeID)), URLQueryItem(name: "type", value: type)]
        } else {
            return nil
        }
    }
}
struct FSQCommentsRequest: APIRequest {
    typealias Response = [Comment]
    typealias IsImage =  Void
    
    var fsqID: String?
    var type: String?
    
    var path: String { "/Consierge/fsqcomments.php" }
    
    var queryItems: [URLQueryItem]? {
        if let fsqID = fsqID {
            return [URLQueryItem(name: "fsqID", value: String(fsqID)), URLQueryItem(name: "type", value: type)]
        } else {
            return nil
        }
    }
}

//Add a comment to a Place
struct AddCommentRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var comment: Comment
    
    var path: String { "/Consierge/newComment.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(comment)
    }
}
struct AddFSQCommentRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var comment: Comment
    
    var path: String { "/Consierge/newFSQComment.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(comment)
    }
}

struct commentUpvoteRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var commentUpvote: CommentUpvote
    
    var path: String { "/Consierge/commentUpvote.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(commentUpvote)
    }
}

//Delete a 'Loved' Place from the DB
struct commentDownvoteRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var commentUpvote: CommentUpvote
    
    var path: String { "/Consierge/commentDownvote.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(commentUpvote)
    }
}

//get all activities a specified user has loved from the DB
struct UserCommentVotesRequest: APIRequest {
    typealias Response = [CommentUpvote]
    typealias IsImage =  Void
    
    var userID: Int
    
    var path: String { "/Consierge/userCommentVotes.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID))]
    }
}

struct GetPlaceCategoryRequest: APIRequest {
    typealias Response = [Genre]
    typealias IsImage =  Void
    
    var category: String?
    var placeTypeID: Int?
    
    var path: String { "/Consierge/getPlaceCategory.php" }
    
    var queryItems: [URLQueryItem]? {
        if let placeTypeID = placeTypeID, let category = category {
            return [URLQueryItem(name: "placeTypeID", value: String(placeTypeID)), URLQueryItem(name: "category", value: category)]
        } else {
            return nil
        }
    }
}

struct GetPlaceNeighborhoodRequest: APIRequest {
    typealias Response = [Neighborhood]
    typealias IsImage =  Void
    
    var neighborhood: String?
    var cityID: Int?
    
    var path: String { "/Consierge/getPlaceNeighborhood.php" }
    
    var queryItems: [URLQueryItem]? {
        if let cityID = cityID, let neighborhood = neighborhood {
            return [URLQueryItem(name: "cityID", value: String(cityID)), URLQueryItem(name: "neighborhood", value: neighborhood)]
        } else {
            return nil
        }
    }
}

//Send a new 'Additional Photo' entry to the DB
struct AdditionalPhotoRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var additionalPhoto: AdditionalPhoto
    var path: String { "/Consierge/additionalPhoto.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(additionalPhoto)
    }
}

//Get all specified 'Additional Photo' entries for a specified Place ID
struct GetAdditionalPhotosRequest: APIRequest {
    typealias Response = [AdditionalPhoto]
    typealias IsImage =  Void
    
    var restaurantID: Int?
    var type: String?
    
    var path: String { "/Consierge/getAdditionalPhotos.php" }
    
    var queryItems: [URLQueryItem]? {
        if let restaurantID = restaurantID {
            return [URLQueryItem(name: "restaurantID", value: String(restaurantID)), URLQueryItem(name: "type", value: type)]
        } else {
            return nil
        }
    }
}

//Get all itineraries from the DB
struct ItineraryRequest: APIRequest {
    typealias Response = [Itinerary]
    typealias IsImage =  Void
    
    var userID: Int
    var cityID: Int
    
    var path: String { "/Consierge/itineraries.php" }

    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID)), URLQueryItem(name: "cityID", value: String(cityID))]
    }
}

//Create a new Itinerary Line
struct NewItineraryLineRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var itinerary: ItineraryWithLine
    
    var path: String { "/Consierge/newItineraryLine.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(itinerary)
    }
}
//Create a brand new Itinerary and add the first Itinerary Line
struct BrandNewItineraryRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var itinerary: ItineraryWithLine
    
    var path: String { "/Consierge/brandNewItinerary.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(itinerary)
    }
}

//Get all of the itineraries created by a specified user
struct UserItinerariesRequest: APIRequest {
    typealias Response = [Itinerary]
    typealias IsImage =  Void
    
    var userID: Int
    
    var path: String { "/Consierge/userItineraries.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "userID", value: String(userID))]
    }
}

//Get all of the itinerary Lines for a specified Itinerary
struct UserItineraryLinesRequest: APIRequest {
    typealias Response = [ItineraryLine]
    typealias IsImage =  Void
    
    var itineraryID: Int
    
    var path: String { "/Consierge/userItineraryLines.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "itineraryID", value: String(itineraryID))]
    }
}

//Update the details of an itinerary Line
struct UpdateItineraryLineRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var itineraryLine: ItineraryLine
    
    var path: String { "/Consierge/updateItineraryLine.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(itineraryLine)
    }
}

//Update the details of an itinerary Line
struct DeleteItineraryLineRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var itineraryLine: ItineraryLine
    
    var path: String { "/Consierge/deleteItineraryLine.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(itineraryLine)
    }
}

//review all restaurants in the DB
struct GetOrCreateCityRequest: APIRequest {
    typealias Response = City
    typealias IsImage =  Void
    
    var city: City
    
    var path: String { "/Consierge/getOrCreateCity.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(city)
    }
}

//review all restaurants in the DB
struct GetOrCreatePlaceTypeRequest: APIRequest {
    typealias Response = PlaceType
    typealias IsImage =  Void
    
    var placeType: PlaceType
    
    var path: String { "/Consierge/getOrCreatePlaceType.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(placeType)
    }
}


//review all restaurants in the DB
struct GetOrCreateGenreRequest: APIRequest {
    typealias Response = Genre
    typealias IsImage =  Void
    
    var genre: Genre
    
    var path: String { "/Consierge/getOrCreateGenre.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(genre)
    }
}


//review all restaurants in the DB
struct GetOrCreateNeighborhoodRequest: APIRequest {
    typealias Response = Neighborhood
    typealias IsImage =  Void
    
    var neighborhood: Neighborhood
    
    var path: String { "/Consierge/getOrCreateNeighborhood.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(neighborhood)
    }
}


//Create a new Itinerary Line
struct NewPlaceRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var place: ConciergePlace
    
    var path: String { "/Consierge/newPlace.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(place)
    }
}

struct PlaceExistsRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var placeName: String
    var address: String
    
    var path: String { "/Consierge/placeExists.php" }

    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "placeName", value: placeName), URLQueryItem(name: "address", value: address)]
    }
}

//review all restaurants in the DB
struct GetCityRequest: APIRequest {
    typealias Response = City
    typealias IsImage =  Void
    
    var cityID: Int
    
    var path: String { "/Consierge/getCity.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "cityID", value: String(cityID))]
    }
}

//review all restaurants in the DB
struct GetPlaceTypeRequest: APIRequest {
    typealias Response = PlaceType
    typealias IsImage =  Void
    
    var placeTypeID: Int
    
    var path: String { "/Consierge/getPlaceType.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "placeTypeID", value: String(placeTypeID))]
    }
}


// MARK: Image Requests

//Upload an image to the server
struct NewImageRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage = Bool
    
    var imageUpload: ImageUpload
    
    var path: String { "/Consierge/newImageToS3.php" }
    
    var postData: Data? {
        var body = Data()
        let lineBreak = "\r\n"
        let boundary = "Boundary-18IndyPeyton18 Swift Boundary"


        for (paramKey, paramValue) in imageUpload.params {
            body.append("--\(boundary + lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(paramKey)\"\(lineBreak + lineBreak)")
            body.append("\(paramValue + lineBreak)")
          
        }
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(imageUpload.key)\"; filename=\"\(imageUpload.fileName)\"\(lineBreak)")
        body.append("Content-Type: \(imageUpload.mimeType + lineBreak + lineBreak)")
        body.append(imageUpload.data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
}
//Data extension used to allow appending for the Image Upload request Body.
extension Data {
   mutating func append(_ string: String) {
      if let data = string.data(using: .utf8) {
         append(data)
      }
   }
}

struct UpdateUserProfPicRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var profilePic: ProfilePic
    
    var path: String { "/Consierge/updateUserProfPic.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(profilePic)
    }
}

struct DeleteItineraryRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var itinerary: Itinerary
    
    var path: String { "/Consierge/deleteItinerary.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(itinerary)
    }
}

struct PlacesAuthoredNumRequest: APIRequest {
    typealias Response = Int
    typealias IsImage =  Void
    
    var userID: Int?
    
    var path: String { "/Consierge/getPlacesAuthoredNum.php" }
    
    var queryItems: [URLQueryItem]? {
        if let userID = userID {
            return [URLQueryItem(name: "userID", value: String(userID))]
        } else {
            return nil
        }
    }
}

struct PlacesAuthoredRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var userID: Int?
    
    var path: String { "/Consierge/getPlacesAuthored.php" }
    
    var queryItems: [URLQueryItem]? {
        if let userID = userID {
            return [URLQueryItem(name: "userID", value: String(userID))]
        } else {
            return nil
        }
    }
}

//get all restaurants a specified user has loved from the DB
struct CommunityLovesUsersRequest: APIRequest {
    typealias Response = [User]
    typealias IsImage =  Void
    
    var placeID: Int
    
    var path: String { "/Consierge/communityLovesUsers.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "placeID", value: String(placeID))]
    }
}
//get all cafes a specified user has loved from the DB
struct CommunityLovesPlacesRequest: APIRequest {
    typealias Response = [LovePlace]
    typealias IsImage =  Void
    
    var placeID: Int
    
    var path: String { "/Consierge/communityLovesPlaces.php" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "placeID", value: String(placeID))]
    }
}


// MARK: Admin Requests

//review all cities in the DB
struct CitiesToReviewRequest: APIRequest {
    typealias Response = [City]
    typealias IsImage =  Void
        
    var path: String { "/Consierge/citiesToReview.php" }
}

//review all restaurants in the DB
struct PlacesToReviewRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/placesToReview.php" }
}

//Approve a new city
struct ApproveCityRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var city: City
    
    var path: String { "/Consierge/approveCity.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(city)
    }
}

//Approve a new restaurant
struct ApprovePlaceRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var place: ConciergePlace
    
    var path: String { "/Consierge/approvePlace.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(place)
    }
}

//Approve a new restaurant
struct ApprovePlaceEditRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var place: ConciergePlace
    
    var path: String { "/Consierge/approvePlaceEdit.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(place)
    }
}

//return all restaurants in the DB
struct PlaceEditsToReviewRequest: APIRequest {
    typealias Response = [ConciergePlace]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/placeEditsToReview.php" }
}

//Get all specified 'Additional Photo' entries for a specified Place ID
struct GetAdditionalPhotosToReviewRequest: APIRequest {
    typealias Response = [AdditionalPhoto]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/additionalPhotosToReview.php" }
}

struct ApproveAdditionalPhotoRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var additionalPhoto: AdditionalPhoto
    
    var path: String { "/Consierge/approveAdditionalPhoto.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(additionalPhoto)
    }
}

struct GetCommentsToReviewRequest: APIRequest {
    typealias Response = [Comment]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/commentsToReview.php" }
}

struct ApproveCommentRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var comment: Comment
    
    var path: String { "/Consierge/approveComment.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(comment)
    }
}

struct GetTagsToReviewRequest: APIRequest {
    typealias Response = [ReviewTag]
    typealias IsImage =  Void
    
    var path: String { "/Consierge/tagsToReview.php" }
}

struct ApprovePlaceTagRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var tag: ReviewTag
    
    var path: String { "/Consierge/approvePlaceTag.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(tag)
    }
}


// MARK: FSQ Requests

struct FSQPlaceLLRequest: FSQAPIRequest {
    typealias Response = FSQDecoderParent
    typealias IsImage =  Void
    
    var category: String
    var ll: String
    var radius: Int
    var sort: String
    var limit: Int
    
    var path: String { "/v3/places/search" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "ll", value: ll), URLQueryItem(name: "categories", value: category), URLQueryItem(name: "radius", value: String(radius)), URLQueryItem(name: "exclude_all_chains", value: String(true)), URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity"), URLQueryItem(name: "sort", value: sort), URLQueryItem(name: "limit", value: String(limit))]
    }
}

struct FSQPlaceNearRequest: FSQAPIRequest {
    typealias Response = FSQDecoderParent
    typealias IsImage =  Void
    
    var categories: String?
    var near: String
    var sort: String
    var limit: Int
    
    var path: String { "/v3/places/search" }
    
    var queryItems: [URLQueryItem]? {
        var qi = [URLQueryItem(name: "near", value: near), URLQueryItem(name: "exclude_all_chains", value: String(true)), URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity"), URLQueryItem(name: "sort", value: sort), URLQueryItem(name: "limit", value: String(limit))]
        if categories != nil {
            qi.append(URLQueryItem(name: "categories", value: categories))
        }
        return qi
    }
}

struct FSQQueryRequest: FSQAPIRequest {
    typealias Response = FSQDecoderParent
    typealias IsImage =  Void
    
    var query: String
    var ll: String
    var radius: Int
    var sort: String
    var limit: Int
    
    var path: String { "/v3/places/search" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "ll", value: ll), URLQueryItem(name: "query", value: query), URLQueryItem(name: "radius", value: String(radius)), URLQueryItem(name: "exclude_all_chains", value: String(false)), URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity"), URLQueryItem(name: "sort", value: sort), URLQueryItem(name: "limit", value: String(limit))]
    }
}

struct FSQExactPlaceRequest: FSQAPIRequest {
    typealias Response = FSQDecoderParent
    typealias IsImage =  Void
    
    var query: String
    var near: String
    
    var path: String { "/v3/places/search" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "near", value: near), URLQueryItem(name: "query", value: query), URLQueryItem(name: "exclude_all_chains", value: String(false)), URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity"), URLQueryItem(name: "sort", value: "RELEVANCE"), URLQueryItem(name: "limit", value: "1")]
    }
}

struct getFSQPlaceRequest: FSQAPIRequest {
    typealias Response = FSQDecoder
    typealias IsImage =  Void
    
    var fsqID: String
    
    var path: String { "/v3/places/\(fsqID)" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity")]
    }
}



//struct GoogleFindCandidatePlacesRequest: GooglePlacesAPIRequest {
//    typealias Response = GoogleCandidatePlacesDecoder
//    typealias IsImage =  Void
//    
//    var textQuery: String
//    var location: String
//    
//    var path: String { "/maps/api/place/textsearch/json" }
//    
//    var queryItems: [URLQueryItem]? {
//        return [URLQueryItem(name: "query", value: textQuery), URLQueryItem(name: "radius", value: "100000"), URLQueryItem(name: "location", value: location), URLQueryItem(name: "key", value: googlyKey)]
//    }
//}
//struct GoogleFindPlaceRequest: GooglePlacesAPIRequest {
//    typealias Response = GooglePlaceFindDecoder
//    typealias IsImage =  Void
//    
//    var textQuery: String
//    
//    var path: String { "/maps/api/place/findplacefromtext/json" }
//    
//    var queryItems: [URLQueryItem]? {
//        return [URLQueryItem(name: "input", value: textQuery), URLQueryItem(name: "inputtype", value: "textquery"), URLQueryItem(name: "key", value: googlyKey)]
//    }
//}
//struct GooglePlaceDetailRequest: GooglePlacesAPIRequest {
//    typealias Response = GooglePlaceDecoderParent
//    typealias IsImage =  Void
//    
//    var placeID: String
//    
//    var path: String { "/maps/api/place/details/json" }
//    
//    var queryItems: [URLQueryItem]? {
//        return [URLQueryItem(name: "place_id", value: placeID), URLQueryItem(name: "key", value: googlyKey)]
//    }
//}
//struct GooglePlacePhotoRequest: GooglePlacesAPIRequest {
//    typealias Response = UIImage
//    typealias IsImage =  Void
//    
//    var photo_reference: String
//    
//    var path: String { "/maps/api/place/photo" }
//    
//    var queryItems: [URLQueryItem]? {
//        return [URLQueryItem(name: "photo_reference", value: photo_reference), URLQueryItem(name: "key", value: googlyKey), URLQueryItem(name: "maxheight", value: String(100000)), URLQueryItem(name: "maxwidth", value: String(100000))]
//    }
//}

struct ChatGPTCompletionRequest: OpenAIAPIRequest {
    struct Response: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let role: String
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    var model: String
    var systemPrompt: String
    var prompts: [String]  // Updated to accept an array of prompts
    var maxTokens: Int
    var temperature: Double
    var username: String

    var path: String { "/v1/chat/completions" }
    var queryItems: [URLQueryItem]? { nil }

    var body: Data? {
        // Construct the messages array
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "system", "content": "username: \(username)"]
        ]
        
        // Append each user prompt to the messages
        for prompt in prompts {
            messages.append(["role": "user", "content": prompt])
        }
        
        let parameters: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": maxTokens,
            "temperature": temperature
        ]
        return try? JSONSerialization.data(withJSONObject: parameters)
    }
}

