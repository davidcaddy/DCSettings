//
//  DCSettingsManager.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation
import SwiftUI
import Combine

/**
 `DCSettingsManager` is a class that manages the configuration and storage of your app's settings.
 
 You can use the shared instance of `DCSettingsManager` to configure your settings using the `configure` method. This method takes a closure that uses result builder syntax to create your setting groups and settings.
 
 Once you've configured your settings, you can use the `DCSettingsManager` instance to access their values. The `value(for:)` method allows you to retrieve the value of a setting by its key, while the `setValue(_:for:)` method allows you to set the value of a setting by its key.
 
 `DCSettingsManager` also provides several properties that allow you to access your setting groups and settings directly. These properties include the `groups` property, which returns an array of all your setting groups, and the `setting(for:)` method, which returns a `DCSettable` instance for a given key.
 */
public class DCSettingsManager {
    
    public static let shared = DCSettingsManager()
    
    private(set) var groups: [DCSettingGroup] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {}
    
    public func configure(@DCSettingGroupsBuilder _ builder: () -> [DCSettingGroup]) {
        groups = builder()
        for group in groups {
            for setting in group.settings {
                let store = setting.store ?? group.store
                setting.store = store
                setting.refresh()
            }
        }
    }
    
    @discardableResult public func set<ValueType>(_ value: ValueType, forKey key: KeyRepresentable) -> Bool where ValueType: Equatable {
        if let setting = setting(forKey: key) as? DCSetting<ValueType> {
            setting.value = value
            return true
        }
        return false
    }

    public func setting(forKey key: KeyRepresentable) -> (any DCSettable)? {
        let existingSettings = groups.flatMap({ $0.settings })
        return existingSettings.first(where: { $0.key == key.keyValue })
    }
    
    public func value<ValueType>(forKey key: KeyRepresentable) -> ValueType? where ValueType: Equatable {
        let setting = setting(forKey: key) as? DCSetting<ValueType>
        return setting?.value
    }
    
    public func representedValue<ValueType>(forKey key: KeyRepresentable) -> ValueType? where ValueType: RawRepresentable, ValueType.RawValue: Equatable {
        if let settingRawValue: ValueType.RawValue = value(forKey: key), let option = ValueType(rawValue: settingRawValue)  {
            return option
        }
        return nil
    }
    
    public func valueBinding<ValueType>(forKey key: KeyRepresentable) -> Binding<ValueType>? where ValueType: Equatable {
        if let setting = setting(forKey: key) as? DCSetting<ValueType> {
            return Binding {
                setting.value
            } set: { newValue in
                setting.value = newValue
            }
        }
        return nil
    }
    
    public func bool(forKey key: KeyRepresentable) -> Bool {
        return value(forKey: key) ?? false
    }
    
    public func int(forKey key: KeyRepresentable) -> Int {
        return value(forKey: key) ?? 0
    }
    
    public func double(forKey key: KeyRepresentable) -> Double {
        return value(forKey: key) ?? 0.0
    }
    
    public func string(forKey key: KeyRepresentable) -> String {
        return value(forKey: key) ?? ""
    }
    
    public func date(forKey key: KeyRepresentable) -> Date {
        return value(forKey: key) ?? .distantPast
    }
    
    public func color(forKey key: KeyRepresentable) -> Color {
        return value(forKey: key) ?? .gray
    }
}
