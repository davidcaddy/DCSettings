//
//  DCSetting.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation
import Combine
import SwiftUI

///  A `struct` that represents a setting option.
///
///  Parameters:
///  - label: The label of the option.
///  - mage: The image of the option.
///  - systemImage: The system image of the option.
///  - value: The value of the option.
///  - isDefault: Whether the option is the default option.
///
///  Note: The value type must be equatable.
public struct DCSettingOption<ValueType>: Equatable where ValueType: Equatable {
    public let label: String?
    public let image: String?
    public let systemImage: String?
    public let value: ValueType
    public let isDefault: Bool
    
    private init(value: ValueType, label: String?, image: String?, systemImage: String?, default isDefault: Bool = false) {
        self.value = value
        self.label = label
        self.image = image
        self.systemImage = systemImage
        self.isDefault = isDefault
    }
    
    public init(value: ValueType, default isDefault: Bool = false) where ValueType: LosslessStringConvertible {
        self.init(value: value, label: String(value), image: nil, systemImage: nil, default: isDefault)
    }
    
    public init(value: ValueType, label: String, default isDefault: Bool = false) {
        self.init(value: value, label: label, image: nil, systemImage: nil, default: isDefault)
    }
    
    public init(value: ValueType, image: String, default isDefault: Bool = false) {
        self.init(value: value, label: nil, image: image, systemImage: nil, default: isDefault)
    }
    
    public init(value: ValueType, systemImage: String, default isDefault: Bool = false) {
        self.init(value: value, label: nil, image: nil, systemImage: systemImage, default: isDefault)
    }
    
    public init(value: ValueType, label: String, image: String, default isDefault: Bool = false) {
        self.init(value: value, label: label, image: image, systemImage: nil, default: isDefault)
    }
    
    public init(value: ValueType, label: String, systemImage: String, default isDefault: Bool = false) {
        self.init(value: value, label: label, image: nil, systemImage: systemImage, default: isDefault)
    }
}

@resultBuilder
public struct DCSettingOptionsBuilder {
    public static func buildBlock<T>(_ settings: DCSettingOption<T>...) -> [DCSettingOption<T>] {
        settings
    }
}

/// A `struct` that represents the value bounds.
public struct DCValueBounds<ValueType>: Equatable where ValueType: Equatable {
    public let lowerBound: ValueType
    public let upperBound: ValueType
}

/**
 `DCSettingConfiguration` represents the configuration options for a `DCSetting`.
 
 A `DCSettingConfiguration` instance can specify several options that affect how a `DCSetting` is displayed and used. These options include an array of `DCSettingOption` instances that represent the available options for the setting, a `DCValueBounds` instance that specifies the range of valid values for the setting, and a step value that specifies the increment between valid values for the setting.
 
 You can create a `DCSettingConfiguration` instance and pass it to the initializer of a `DCSetting` to configure its options. You can also use result builder syntax to create a `DCSettingConfiguration` instance when configuring your settings using the `DCSettingsManager.shared.configure` method.
 */
public struct DCSettingConfiguration<ValueType>: Equatable where ValueType: Equatable {
    public let options: [DCSettingOption<ValueType>]?
    public let bounds: DCValueBounds<ValueType>?
    public let step: ValueType?
}

/**
 `DCSettable` is a protocol that represents a setting that can be displayed and edited within a `DCSettingsView`.
 
 Types that conform to the `DCSettable` protocol must provide several properties that define the key, value, and label of the setting. They must also provide methods for binding the value of the setting to a user interface control.
 
 `DCSetting` is a concrete type that conforms to the `DCSettable` protocol. You can use `DCSetting` instances directly to represent your settings, or you can create your own custom types that conform to the `DCSettable` protocol if you need more control over how your settings are displayed and used.
 */
public protocol DCSettable<ValueType>: ObservableObject where ValueType: Equatable {
    associatedtype ValueType
    
    var label: String? { get }
    var key: String { get }
    var value: ValueType { get set }
    var configuation: DCSettingConfiguration<ValueType>? { get }
    var store: DCSettingStore? { get set }
    
    func refresh()
}

/**
 `DCSetting` represents a single setting within a `DCSettingGroup`.
 
 Each `DCSetting` has a key that uniquely identifies it within its group. The key is used to store and retrieve the value of the setting.
 
 In addition to its key, a `DCSetting` can also have several other properties that affect how it is displayed and used. These properties include a default value, a label, and a configuration that specifies additional options such as value bounds and step size.
 
 `DCSetting` supports several built-in value types, including `Bool`, `Int`, `Double`, `String`,  `Date` and `Color`. You can also use custom types as the value type for your settings by making them conform to the `Codable` protocol.
 */
public class DCSetting<ValueType>: DCSettable where ValueType: Equatable {
    
    public let key: String
    public let label: String?
    public var value: ValueType {
        didSet {
            objectWillChange.send()
            save()
        }
    }
    public var store: DCSettingStore?
    public let configuation: DCSettingConfiguration<ValueType>?
    
    private var cancellable: AnyCancellable?
    
    init(key: KeyRepresentable, value: ValueType, label: String?, configuation: DCSettingConfiguration<ValueType>?, store: DCSettingStore?) {
        self.key = key.keyValue
        self.value = value
        self.label = label
        self.store = store
        self.configuation = configuation
    }
    
    public convenience init(key: KeyRepresentable, defaultValue: ValueType, label: String? = nil, store: DCSettingStore? = .standard) {
        self.init(key: key.keyValue, value: defaultValue, label: label, configuation: nil, store: store)
    }
    
    public convenience init?(key: KeyRepresentable, label: String? = nil, store: DCSettingStore? = .standard, options: [ValueType], defaultIndex: Int) where ValueType: LosslessStringConvertible {
        if let defaultValue = options.get(defaultIndex) {
            let configuredOptions = options.map { DCSettingOption(value: $0) }
            self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
        }
        else {
            return nil
        }
    }
    
    public convenience init?(key: KeyRepresentable, defaultValue: ValueType, label: String? = nil, store: DCSettingStore? = .standard, lowerBound: ValueType, upperBound: ValueType, step: ValueType? = nil) where ValueType: Numeric {
        self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: nil, bounds: DCValueBounds(lowerBound: lowerBound, upperBound: upperBound), step: step), store: store)
    }
    
    public convenience init?(key: KeyRepresentable, label: String? = nil, store: DCSettingStore? = .standard, @DCSettingOptionsBuilder _ builder: () -> [DCSettingOption<ValueType>]) {
        let configuredOptions = builder()
        if let defaultValue = configuredOptions.first(where: { $0.isDefault } )?.value ?? configuredOptions.first?.value {
            self.init(key: key, value: defaultValue, label: label, configuation: DCSettingConfiguration<ValueType>(options: configuredOptions, bounds: nil, step: nil), store: store)
        }
        else {
            return nil
        }
    }
    
    public func refresh() {
        if let newValue: ValueType = store?.object(forKey: key) {
            if value != newValue {
                value = newValue
                objectWillChange.send()
            }
            setUpListener()
        }
    }
    
    private func save() {
        cancellable = nil
        store?.set(value, forKey: key)
        setUpListener()
    }
    
    public func valueBinding() -> Binding<ValueType> {
        return Binding {
            self.value
        } set: { newValue in
            self.value = newValue
        }
    }
    
    private func setUpListener() {
        guard let store = store else { return }
        cancellable = store.publisher(forKey: key)
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                if let newTypedValue = newValue as? ValueType, self?.value != newTypedValue {
                    self?.value = newTypedValue
                }
            }
    }
}

@resultBuilder
public struct DCSettingsBuilder {
    public static func buildBlock(_ settings: (any DCSettable)?...) -> [any DCSettable] {
        settings.compactMap { $0 }
    }
}

/**
 `DCStorage` is a property wrapper that provides a convenient way to access and update your app's settings from within a SwiftUI view.
 
 To use this property wrapper, you'll need to create a property in your view and annotate it with the `@DCStorage` attribute. You'll also need to provide the key for the setting you want to access and a default value for the setting.
 
 Once you've created a property using the `@DCStorage` property wrapper, you can use it like any other property in your view. When you read its value, it will return the current value of the setting. When you write its value, it will update the value of the setting.
 */
@available(iOS 14.0, *)
@propertyWrapper
public struct DCStorage<T>: DynamicProperty where T: Equatable {
    @StateObject private var setting: DCSetting<T>

    public var wrappedValue: T {
        get {
            setting.value
        }

        nonmutating set {
            setting.value = newValue
        }
    }

    public init(_ key: KeyRepresentable, default defaultValue: T, settingsManager: DCSettingsManager = .shared) {
        if let setting = settingsManager.setting(forKey: key) as? DCSetting<T> {
            _setting = StateObject(wrappedValue: setting)
        }
        else {
            _setting = StateObject(wrappedValue: DCSetting(key: key, defaultValue: defaultValue))
        }
    }
}
