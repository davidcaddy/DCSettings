//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation

extension String: DCKeyRepresentable {
    
    /// The key value of the string.
    ///
    /// This property returns the string itself.
    public var keyValue: String {
        return self
    }
}

extension UUID: DCKeyRepresentable {
    
    /// The key value of the `UUID`.
    ///
    /// This property returns the string representation of the `UUID`.
    public var keyValue: String {
        return self.uuidString
    }
}
