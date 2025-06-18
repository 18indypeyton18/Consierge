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
                    if place.coverStatus != "Approved" {
                        delegate?.updatePic(image: UIImage(named: "default.png"), placeID: nil)
                        return
                    }
                    placePics.append(coverImage)
                }
                for additionalPhoto in additionalPhotos {
                    if additionalPhoto.photoIndex == 1 { continue }
                    if additionalPhoto.photoIndex > 10 { break }
                    if let image = try? await ImageRequest(path: additionalPhoto.path).send() {
                        placePics.append(image)
                        delegate?.updatePics(images: placePics)
                    }
                }
            } else {
                if place.coverStatus != "Approved" {
                    delegate?.updatePic(image: UIImage(named: "default.png"), placeID: nil)
                    return
                }
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
        if place.coverStatus != "Approved" {
            delegate?.updatePic(image: UIImage(named: "default.png"), placeID: nil)
            return
        }
        imageRequestTask = Task {
            if let img = try? await ImageRequest(path: place.imageURL).send() {
                delegate?.updatePic(image: img, placeID: place.id)
            } else {
                delegate?.updatePic(image: UIImage(named: "default.png"), placeID: place.id)
            }
            imageRequestTask = nil
        }
    }
    func getConciergeImageURLOnly(path: String) {
        imageRequestTask = Task {
            if let img = try? await ImageRequest(path: path).send() {
                delegate?.updatePic(image: img, placeID: nil)
            }
            imageRequestTask = nil
        }
    }
    
    func returnConciergeImage(place: ConciergePlace, i: Int) {
        if place.coverStatus != "Approved" {
            return
        }
        imageRequestTask = Task { @MainActor in
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
                delegate?.updatePic(image: image, placeID: nil)
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
    func fetchImage(place: Place) {
        if let place = place as? ConciergePlace {
            getConciergeImage(place: place)
        } else if let place = place as? FSQPlace {
            getFSQImage(imageURL: place.imageURL)
        }
    }
}


protocol PicGetterDelegate: AnyObject {
    func updatePics(images: [UIImage])
    func updatePics(image: UIImage, i: Int?)
    func updatePic(image:UIImage?, placeID: Int?)
    func returnPic(image:UIImage, i: Int)
}
