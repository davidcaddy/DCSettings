//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import Foundation

/// A structure that represents a setting option.
///
/// The `DCSettingOption` struct is used to represent a setting option with an associated value of a specific type.
///
/// The `struct` also includes optional label and image information, as well as a boolean property to indicate whether the option is the default option.
///
/// - Note: The value type must conform to the `Equatable` protocol.
public struct DCSettingOption<ValueType>: Equatable where ValueType: Equatable {
    
    /// An enumeration representing the name of an image for a setting option.
    ///
    /// The `ImageName` enumeration includes two cases: `system` and `custom`. The `system` case represents a system-provided image,
    /// while the `custom` case represents any other image available within the project.
    public enum ImageName: Equatable {
        case system(String)
        case custom(String)
    }
    
    /// An optional label for the setting option.
    public let label: String?
    
    /// An optional image for the setting option.
    public let image: ImageName?
    
    /// The value associated with the setting option.
    public let value: ValueType
    
    /// A boolean value indicating whether the option is the default option.
    public let isDefault: Bool
    
    private init(value: ValueType, label: String?, image: ImageName?, isDefault: Bool = false) {
        self.value = value
        self.label = label
        self.image = image
        self.isDefault = isDefault
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value and default status.
    ///
    /// This initializer creates a new instance of `DCSettingOption` with the label property being set to a string representation of the provided value.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option conforming to `LosslessStringConvertible`.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, default isDefault: Bool = false) where ValueType: LosslessStringConvertible {
        self.init(value: value, label: String(value), image: nil, isDefault: isDefault)
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value, label, and default status.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option.
    ///   - label: A string representing the label for the setting option.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, label: String, isDefault: Bool = false) {
        self.init(value: value, label: label, image: nil, isDefault: isDefault)
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value, image, and default status.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option.
    ///   - image: A string representing the name of an image for the setting option.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, image: String, isDefault: Bool = false) {
        self.init(value: value, label: nil, image: .custom(image), isDefault: isDefault)
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value, system image, and default status.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option.
    ///   - systemImage: A string representing the name of a system-provided image for the setting option.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, systemImage: String, isDefault: Bool = false) {
        self.init(value: value, label: nil, image: .system(systemImage), isDefault: isDefault)
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value, label, image, and default status.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option.
    ///   - label: A string representing the label for the setting option.
    ///   - image: A string representing the name of an image for the setting option.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, label: String, image: String, isDefault: Bool = false) {
        self.init(value: value, label: label, image: .custom(image), isDefault: isDefault)
    }
    
    /// Initializes a new `DCSettingOption` instance with the specified value, label, image, and default status.
    ///
    /// - Parameters:
    ///   - value: The value associated with the setting option.
    ///   - label: A string representing the label for the setting option.
    ///   - systemImage: A string representing the name of a system-provided image for the setting option.
    ///   - isDefault: A boolean value indicating whether the option is the default option. The default value is `false`.
    public init(value: ValueType, label: String, systemImage: String, isDefault: Bool = false) {
        self.init(value: value, label: label, image: .system(systemImage), isDefault: isDefault)
    }
}

/// A result builder that constructs an array of `DCSettingOption` instances.
///
/// The `DCSettingOptionsBuilder` struct is a result builder that can be used to construct an array of `DCSettingOption` instances
/// using a closure with multiple `DCSettingOption` expressions.
///
/// ```swift
/// let options: [DCSettingOption<Int>] = DCSettingOptionsBuilder {
///     DCSettingOption(value: 1, label: "One")
///     DCSettingOption(value: 2, label: "Two")
///     DCSettingOption(value: 3, label: "Three")
/// }
/// ```
@resultBuilder
public struct DCSettingOptionsBuilder {
    
    /// Constructs an array of `DCSettingOption` instances from the provided expressions.
    ///
    /// This method is called by the result builder to construct the final result from the provided expressions.
    /// The expressions must be instances of `DCSettingOption`.
    ///
    /// - Parameters:
    ///     - settings: A variadic list of `DCSettingOption` instances.
    ///
    /// - Returns: An array of `DCSettingOption` instances.
    public static func buildBlock<ValueType>(_ settings: DCSettingOption<ValueType>...) -> [DCSettingOption<ValueType>] {
        settings
    }
}
