//
//  DCSetting.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation
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
public struct DCSettingOption<ValueType> where ValueType: Equatable {
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
public struct DCValueBounds<ValueType> where ValueType: Equatable {
    public let lowerBound: ValueType
    public let upperBound: ValueType
}

public struct DCSettingConfiguration<ValueType> where ValueType: Equatable {
    public let options: [DCSettingOption<ValueType>]?
    public let bounds: DCValueBounds<ValueType>?
    public let step: ValueType?
}

public protocol DCSettable<ValueType>: ObservableObject where ValueType: Equatable {
    associatedtype ValueType
    
    var label: String? { get }
    var key: String { get }
    var value: ValueType { get set }
    var configuation: DCSettingConfiguration<ValueType>? { get }
    var store: DCSettingStore? { get set }
    
    func refresh()
}

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
        }
    }
    
    private func save() {
        store?.set(value, forKey: key)
        store?.synchronize()
    }
    
    public func valueBinding() -> Binding<ValueType> {
        return Binding {
            self.value
        } set: { newValue in
            self.value = newValue
        }
    }
}

@resultBuilder
public struct DCSettingsBuilder {
    public static func buildBlock(_ settings: (any DCSettable)?...) -> [any DCSettable] {
        settings.compactMap { $0 }
    }
}
