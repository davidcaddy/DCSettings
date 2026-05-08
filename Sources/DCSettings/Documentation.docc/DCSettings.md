# ``DCSettings``

DCSettings is a Swift package that simplifies the configuration of user preferences with an easy-to-use result builder syntax and a drop-in SwiftUI settings UI for iOS, macOS, watchOS, and visionOS.

## Overview

To configure settings, use the `configure` method on a ``DCSettingsManager`` instance, typically the shared singleton instance. ``DCSettingsManager`` is main-actor isolated, so call `configure` from the main actor. This method takes a closure that returns an array of ``DCSettingGroup`` instances. Each ``DCSettingGroup`` can contain multiple ``DCSetting`` instances. Settings will be stored in `UserDefaults`, `NSUbiquitousKeyValueStore` or a custom key-value store depending on how they are configured.

Once your settings are set up, you can quickly add a settings view to your app using ``DCSettingsView`` on iOS, macOS, watchOS, and visionOS. This view displays a list of all the setting groups and settings that you’ve configured using the given ``DCSettingsManager``. You can create an instance of this view and add it to your app’s view hierarchy like any other SwiftUI view.

> Note: The settings configuration and storage APIs support the package's minimum platform versions, except ``DCSettingStore/ubiquitous`` requires watchOS 9 or newer. ``DCSettingView``, ``DCSettingsView``, and ``DCSettingViewProviding`` are not available on tvOS in 1.0.

> Note: In the default watchOS settings UI, `Date` settings are editable with SwiftUI's date picker on watchOS 10 or newer and display-only on earlier watchOS versions. `Color` settings are display-only on watchOS.

> Note: ``DCSettingsManager``, ``DCSetting``, the stored-value property wrappers, and the SwiftUI settings views are main-actor isolated. The lower-level ``DCSettingStore`` and ``DCKeyValueStore`` storage APIs remain actor-neutral.

DCSettings stores property-list compatible values (`Bool`, `Int`, `Double`, `String`, `Date`, and `Data`) directly in the selected backing store. On platforms with UIKit or AppKit, `Color` values are handled as a built-in type and stored as JSON-encoded `Data`. Other values must conform to `Codable`; they are JSON-encoded to `Data` before storage and decoded when read back. ``DCSetting`` value types must be non-optional; model unset, inherited, or system-default states with a concrete default value or an explicit enum case. Values that are neither property-list compatible nor a supported `Color` or `Codable` value are rejected in debug builds with an assertion and are not persisted. Custom ``DCKeyValueStore`` implementations should accept `Data` values to support custom `Codable` setting types.

Group keys and setting keys must be unique across all groups configured in a ``DCSettingsManager``. `DCSettingGroup("General")` uses `"General"` as both the group label and group key. Prefer ``DCSettingGroup/init(key:label:store:settings:)`` when the key is persisted, filtered, localized, or otherwise part of app behavior. `DCSettingGroup()` uses a generated key and is best reserved for groups that never need stable identity.

Configured options and comparable bounds are treated as validation rules when a ``DCSetting`` is initialized, written, or refreshed. Values outside the configured option list or bounds are ignored. The configuration `step` value is used by editing controls as a positive increment hint; bounded ``DCSetting`` initializers reject non-positive or non-finite step values.

*Example configuration:*

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "refreshInterval") {
            DCSettingOption(value: 5, label: "5 mins")
            DCSettingOption(value: 10, label: "10 mins")
            DCSettingOption(value: 15, label: "15 mins")
            DCSettingOption(value: 30, label: "30 mins").default()
            DCSettingOption(value: 60, label: "60 mins")
        }
        DCSetting(key: "articleListLayout") {
            DCSettingOption(value: "List", label: "List", systemImage: "list.bullet")
            DCSettingOption(value: "Grid", label: "Grid", systemImage: "square.grid.2x2")
        }
        DCSetting(key: "showImages", defaultValue: true)
        DCSetting(key: "showFullContent", defaultValue: false)
        DCSetting(key: "markAsReadOnScroll", defaultValue: true)
        DCSetting(key: "maxSyncItems", defaultValue: 1000)
    }
    DCSettingGroup(key: "appearance", label: "Appearance") {
        DCSetting(key: "theme", label: "Theme") {
            DCSettingOption(value: "Light", label: "Light")
            DCSettingOption(value: "Dark", label: "Dark")
        }
        DCSetting(key: "fontSize", label: "Font Size") {
            DCSettingOption(value: 12, label: "12 pt")
            DCSettingOption(value: 14, label: "14 pt")
            DCSettingOption(value: 16, label: "16 pt").default()
            DCSettingOption(value: 18, label: "18 pt")
            DCSettingOption(value: 20, label: "20 pt")
        }
        DCSetting(key: "lineSpacing", defaultValue: 1.2, lowerBound: 1.0, upperBound: 1.6, step: 0.1)
        DCSetting(key: "highlightColor", defaultValue: Color.blue)
    }
}
```

*Corresponding settings view:*

![Settings View](SettingsView.png)

```swift
DCSettingsView()
```
