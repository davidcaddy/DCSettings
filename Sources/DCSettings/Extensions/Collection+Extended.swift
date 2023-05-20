//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
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
