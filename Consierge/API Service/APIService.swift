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

//return all cities in the DB
struct CityRequest: APIRequest {
    typealias Response = [City]
    typealias IsImage =  Void
        
    var path: String { "/Consierge/cities.php" }
}

//Get image from the server for a specified Image URL
struct ImageRequest: APIRequest {
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

struct addTagRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage =  Void
    
    var addTag: AddTag
    
    var path: String { "/Consierge/addTag.php" }
    
    var postData: Data? {
        let encoder = JSONEncoder()
        return try! encoder.encode(addTag)
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
    
    var path: String { "/Consierge/cityTags.php" }
    
    var queryItems: [URLQueryItem]? {
        if let cityID = cityID {
            return [URLQueryItem(name: "cityID", value: String(cityID))]
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

//Upload an image to the server
struct NewImageRequest: APIRequest {
    typealias Response = Dictionary<String, String>
    typealias IsImage = Bool
    
    var imageUpload: ImageUpload
    
    var path: String { "/Consierge/newImage.php" }
    
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
struct getFSQPlaceRequest: FSQAPIRequest {
    typealias Response = FSQDecoder
    typealias IsImage =  Void
    
    var fsqID: String
    
    var path: String { "/v3/places/\(fsqID)" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "fields", value: "fsq_id,name,description,photos,categories,location,website,price,geocodes,rating,popularity")]
    }
}




public var googlyKey = "AIzaSyCtsKYOe5RHp72eGTVgNff5TE_CziXs0E4"
struct GoogleFindCandidatePlacesRequest: GooglePlacesAPIRequest {
    typealias Response = GoogleCandidatePlacesDecoder
    typealias IsImage =  Void
    
    var textQuery: String
    var location: String
    
    var path: String { "/maps/api/place/textsearch/json" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "query", value: textQuery), URLQueryItem(name: "radius", value: "100000"), URLQueryItem(name: "location", value: location), URLQueryItem(name: "key", value: googlyKey)]
    }
}
struct GoogleFindPlaceRequest: GooglePlacesAPIRequest {
    typealias Response = GooglePlaceFindDecoder
    typealias IsImage =  Void
    
    var textQuery: String
    
    var path: String { "/maps/api/place/findplacefromtext/json" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "input", value: textQuery), URLQueryItem(name: "inputtype", value: "textquery"), URLQueryItem(name: "key", value: googlyKey)]
    }
}
struct GooglePlaceDetailRequest: GooglePlacesAPIRequest {
    typealias Response = GooglePlaceDecoderParent
    typealias IsImage =  Void
    
    var placeID: String
    
    var path: String { "/maps/api/place/details/json" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "place_id", value: placeID), URLQueryItem(name: "key", value: googlyKey)]
    }
}
struct GooglePlacePhotoRequest: GooglePlacesAPIRequest {
    typealias Response = UIImage
    typealias IsImage =  Void
    
    var photo_reference: String
    
    var path: String { "/maps/api/place/photo" }
    
    var queryItems: [URLQueryItem]? {
        return [URLQueryItem(name: "photo_reference", value: photo_reference), URLQueryItem(name: "key", value: googlyKey), URLQueryItem(name: "maxheight", value: String(100000)), URLQueryItem(name: "maxwidth", value: String(100000))]
    }
}
