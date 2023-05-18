//
//  DCKeyRepresentable.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation

/// A type that can be represented by a key value.
///
/// Conforming types must implement the `keyValue` property to provide a string representation of the instance.
public protocol DCKeyRepresentable {
    
    /// A string representation of the instance.
    var keyValue: String { get }
}
