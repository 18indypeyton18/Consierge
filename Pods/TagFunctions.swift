//
//  TagFunctions.swift
//  Pods
//
//  Created by Austin McLaughlin on 9/21/24.
//

import Foundation

class TagFunctions {
    weak var delegate: TagFunctionDelegate?
    let group = DispatchGroup()
    
    func lovePlace(addTag: AddTag) {
        group.enter()
        Task {
            let resultValue = try? await addTagRequest(addTag: addTag).send()
            if resultValue?["status"] == "Success" {
                print("TagAdded")
            }
            group.leave()
        }
        group.wait()
    }
}
