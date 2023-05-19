//
//  DCSettingConfiguration.swift
//
//  Created by David Caddy on 17/5/2023.
//

import Foundation

/// A structure that represents the configuration of a setting.
///
/// The `DCSettingConfiguration` struct is used to represent the configuration of a setting with a specific value type.
///
/// The struct includes an optional array of `DCSettingOption` instances,
/// an optional `DCValueBounds` instance representing the range of valid values for the setting,
/// and an optional step value that specifies the increment or decrement between valid values.
///
/// - Note: The value type must conform to the `Equatable` protocol.
public struct DCSettingConfiguration<ValueType>: Equatable where ValueType: Equatable {
    
    /// An optional array of `DCSettingOption` instances representing the available options for the setting.
    public let options: [DCSettingOption<ValueType>]?
    
    /// An optional `DCValueBounds` instance representing the range of valid values for the setting.
    public let bounds: DCValueBounds<ValueType>?
    
    /// An optional step value that specifies the increment or decrement between valid values.
    public let step: ValueType?
}
