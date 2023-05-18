//
//  DCKeyRepresentableConformances.swift
//
//  Created by David Caddy on 17/5/2023.
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
    
    /// The key value of the UUID.
    ///
    /// This property returns the string representation of the UUID.
    public var keyValue: String {
        return self.uuidString
    }
}
