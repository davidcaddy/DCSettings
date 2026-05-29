//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation

/// A structure that represents a range of values with a lower and upper bound.
///
/// The `DCValueBounds` struct is used to represent a range of values with a lower and upper bound.
/// The value type must conform to the `Equatable` protocol. Public construction is available
/// for comparable values so the range can be validated.
public struct DCValueBounds<ValueType>: Equatable where ValueType: Equatable {

    /// The lower bound of the range.
    public let lowerBound: ValueType

    /// The upper bound of the range.
    public let upperBound: ValueType

    private init(uncheckedLowerBound lowerBound: ValueType, upperBound: ValueType) {
        self.lowerBound = lowerBound
        self.upperBound = upperBound
    }
}

public extension DCValueBounds where ValueType: Comparable {

    /// Creates a new range of values with lower and upper bounds.
    ///
    /// - Parameters:
    ///   - lowerBound: The lower bound of the range.
    ///   - upperBound: The upper bound of the range.
    init(lowerBound: ValueType, upperBound: ValueType) {
        precondition(lowerBound <= upperBound, "DCValueBounds lowerBound must be less than or equal to upperBound.")

        self.init(uncheckedLowerBound: lowerBound, upperBound: upperBound)
    }
}
