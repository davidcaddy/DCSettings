//
//  Collection+Extended.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation

extension Collection {
    
    func get(_ index: Index) -> Element? {
        if indices.contains(index) {
            return self[index]
        }
        else {
            return nil
        }
    }
}
