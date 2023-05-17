//
//  DCValueBounds.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation

/// A structure that represents a range of values with a lower and upper bound.
///
/// The `DCValueBounds` struct is used to represent a range of values with a lower and upper bound. The value type must conform to the `Equatable` protocol.
///
/// - Parameters:
///   - lowerBound: The lower bound of the range.
///   - upperBound: The upper bound of the range.
public struct DCValueBounds<ValueType>: Equatable where ValueType: Equatable {
    
    /// The lower bound of the range.
    public let lowerBound: ValueType
    
    /// The upper bound of the range.
    public let upperBound: ValueType
}
