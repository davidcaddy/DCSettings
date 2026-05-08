//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation

/// A structure that represents the configuration of a setting.
///
/// The `DCSettingConfiguration` struct is used to represent the configuration of a setting with a specific value type.
///
/// The struct includes an optional array of `DCSettingOption` instances,
/// an optional `DCValueBounds` instance representing the range of valid values for the setting,
/// and an optional step value that specifies the editing increment for controls.
/// Default controls ignore step values that are not positive and finite.
///
/// - Note: The value type must conform to the `Equatable` protocol.
public struct DCSettingConfiguration<ValueType>: Equatable where ValueType: Equatable {

    /// An optional array of `DCSettingOption` instances representing the available options for the setting.
    public let options: [DCSettingOption<ValueType>]?

    /// An optional `DCValueBounds` instance representing the range of valid values for the setting.
    public let bounds: DCValueBounds<ValueType>?

    /// An optional positive step value that specifies the editing increment for controls.
    public let step: ValueType?

    /// Creates a new setting configuration with optional value options, bounds, and step value.
    ///
    /// - Parameters:
    ///   - options: An optional array of setting options representing valid values for the setting.
    ///   - bounds: Optional lower and upper bounds representing valid values for the setting.
    ///   - step: An optional positive increment used by controls that edit the setting.
    public init(options: [DCSettingOption<ValueType>]? = nil, bounds: DCValueBounds<ValueType>? = nil, step: ValueType? = nil) {
        self.options = options
        self.bounds = bounds
        self.step = step
    }
}
