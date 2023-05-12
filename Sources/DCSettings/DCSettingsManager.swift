//
//  DCSettingsManager.swift
//
//  Created by David Caddy on 25/4/2023.
//

import Foundation
import SwiftUI
import Combine

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
        
        for changeNotificationName in groups.flatMap({ $0.settings }).compactMap({ $0.store?.changeNotificationName }).unique() {
            NotificationCenter.default.publisher(for: changeNotificationName)
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] notification in
                    guard let self = self else { return }
                    for group in self.groups {
                        for setting in group.settings {
                            setting.refresh()
                        }
                    }
                })
                .store(in: &cancellables)
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
}
