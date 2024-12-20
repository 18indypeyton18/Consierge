//
//  PicGetter.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/10/24.
//

import UIKit

class PicGetter {
    weak var delegate: PicGetterDelegate?
    
    var imageRequestTask: Task<Void,Never>? = nil
    
    deinit {
        imageRequestTask?.cancel()
    }
    
    func getConciergeImages(place: ConciergePlace, type: String) {
        imageRequestTask = Task {
            var placePics = [UIImage]()
            //Start with fetching the Additional Photos table for that Place ID + type
            if let additionalPhotos = try? await GetAdditionalPhotosRequest(restaurantID: place.id, type: type).send() {
                //If there are Additional Photo results: fetch cover photo then iterate through all additionalPhoto rows and fetch that image
                if let coverImage = try? await ImageRequest(path: place.imageURL).send() {
                    placePics.append(coverImage)
                }
                for additionalPhoto in additionalPhotos {
                    if let image = try? await ImageRequest(path: additionalPhoto.path).send() {
                        placePics.append(image)
                    }
                }
            } else {
                //If there are no Additional Photo results: fetch cover photo only
                if let coverImage = try? await ImageRequest(path: place.imageURL).send() {
                    placePics.append(coverImage)
                }
            }
            delegate?.updatePics(images: placePics)
            imageRequestTask = nil
        }
    }
    
    func getConciergeImage(place: ConciergePlace) {
        imageRequestTask = Task {
            if let img = try? await ImageRequest(path: place.imageURL).send() {
                delegate?.updatePic(image: img)
            }
            imageRequestTask = nil
        }
    }
    func getConciergeImageURLOnly(path: String) {
        imageRequestTask = Task {
            if let img = try? await ImageRequest(path: path).send() {
                delegate?.updatePic(image: img)
            }
            imageRequestTask = nil
        }
    }
    
    func returnConciergeImage(place: ConciergePlace, i: Int) {
        imageRequestTask = Task {
            if let img = try? await ImageRequest(path: place.imageURL).send() {
                
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.returnPic(image: img, i: i)
                }
            }
            imageRequestTask = nil
        }
    }
}

extension PicGetter {
    func getFSQImages(imageURL: String, i: Int) {
        Task {
            if let url = URL(string: imageURL) {
                let image = try await fetchFSQImageThrows(url: url)
                delegate?.updatePics(image: image, i: i)
            }
        }
    }
    func getFSQImage(imageURL: String) {
        Task {
            if let url = URL(string: imageURL) {
                let image = try await fetchFSQImageThrows(url: url)
                delegate?.updatePic(image: image)
            }
        }
    }
    func returnFSQImage(imageURL: String, i: Int) {
        Task {
            if let url = URL(string: imageURL) {
                let image = try await fetchFSQImageThrows(url: url)
                delegate?.returnPic(image: image, i: i)
            }
        }
    }
    
    func fetchFSQImageThrows(url: URL) async throws -> UIImage {
        
        enum PhotoInfoError: Error, LocalizedError {
            case itemNotFound
            case imageDataMissing
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw PhotoInfoError.imageDataMissing
        }
        
        guard let image = UIImage(data: data) else {
            throw PhotoInfoError.imageDataMissing
        }
        
        return image
    }
}

extension PicGetter {
    func getGoogleImages(photo_reference: String, i: Int?) {
        Task {
            let image = try await GooglePlacePhotoRequest(photo_reference: photo_reference).send()
            delegate?.updatePics(image: image, i: i)
        }
    }
    func getGoogleImage(photo_reference: String) {
        Task {
            let image = try await GooglePlacePhotoRequest(photo_reference: photo_reference).send()
            delegate?.updatePic(image: image)
        }
    }
    func returnGoogleImage(photo_reference: String, i: Int) {
        Task {
            let image = try await GooglePlacePhotoRequest(photo_reference: photo_reference).send()
            delegate?.returnPic(image: image, i: i)
        }
    }
}

protocol PicGetterDelegate: AnyObject {
    func updatePics(images: [UIImage])
    func updatePics(image: UIImage, i: Int?)
    func updatePic(image:UIImage)
    func returnPic(image:UIImage, i: Int)
}
