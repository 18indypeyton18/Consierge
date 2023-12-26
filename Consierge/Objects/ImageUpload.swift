//
//  ImageUpload.swift
//  Consierge
//
//  Created by Austin McLaughlin on 1/28/24.
//

import Foundation
import UIKit

struct ImageUpload: Codable {
    let imageURL: String
    let data: Data
    let key: String
    let mimeType: String
    let params: [String:String]
    let fileName: String
    
    
    init?(image:UIImage, imageURL: String, key: String, params: [String:String], fileName: String) {
        self.key = key
        self.imageURL = imageURL
        guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
        self.data = data
        self.mimeType = "image/jpeg"
        self.params = params
        self.fileName = fileName
    }
}
