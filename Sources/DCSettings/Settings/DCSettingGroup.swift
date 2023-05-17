//
//  DCSettingGroup.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation

/**
 `DCSettingGroup` represents a group of related settings.
 
 Each `DCSettingGroup` has a key that uniquely identifies it. The key is used to store and retrieve the values of the settings within the group.
 
 In addition to its key, a `DCSettingGroup` can also have several other properties that affect how it is displayed and used. These properties include a label that provides a human-readable name for the group and an array of `DCSetting` instances that represent the settings within the group.
 
 You can create `DCSettingGroup` instances directly using their initializer, or you can use result builder syntax to create them when configuring your settings using the `DCSettingsManager.shared.configure` method.
 */
public struct DCSettingGroup: Identifiable {
    let key: String
    let label: String?
    let store: DCSettingStore
    let settings: [any DCSettable]
    
    public var id: String {
        return key
    }
    
    public init(key: KeyRepresentable = UUID(), label: String? = nil, store: DCSettingStore = .standard, @DCSettingsBuilder _ builder: () -> [any DCSettable]) {
        self.init(key: key, label: label, store: store, settings: builder())
    }
    
    public init(_ label: String? = nil, store: DCSettingStore = .standard, @DCSettingsBuilder _ builder: () -> [any DCSettable]) {
        self.init(key: nil, label: label, store: store, settings: builder())
    }
    
    init(key: KeyRepresentable?, label: String? = nil, store: DCSettingStore = .standard, settings: [any DCSettable]) {
        self.key = (key ?? UUID()).keyValue
        self.label = label
        self.store = store
        self.settings = settings
    }
}

extension DCSettingGroup {
    public func label(_ label: String) -> DCSettingGroup {
        return DCSettingGroup(key: key, label: label, store: store, settings: settings)
    }
    
    public func store(_ store: DCSettingStore) -> DCSettingGroup {
        return DCSettingGroup(key: key, label: label, store: store, settings: settings)
    }
}

@resultBuilder
public struct DCSettingGroupsBuilder {
    public static func buildBlock(_ settings: DCSettingGroup...) -> [DCSettingGroup] {
        settings
    }
}

