//
//  TagFunctions.swift
//  Consierge
//
//  Created by Austin McLaughlin on 11/30/24.
//

import Foundation

class TagFunctions {
    var addTagRequestTask: Task<Void,Never>? = nil
    deinit {
        addTagRequestTask?.cancel()
    }
    
    func addTag(addTag: AddTag) {
        addTagRequestTask = Task {
            if let result = try? await AddTagRequest(addTag: addTag).send() {
                print("add tag success")
            } else {
                print("add tag err")
            }
            addTagRequestTask = nil
        }
    }
}
