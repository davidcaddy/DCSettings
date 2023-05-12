//
//  DCSettingGroup.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation

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

