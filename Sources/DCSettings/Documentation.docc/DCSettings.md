# ``DCSettings``

DCSettings is a Swift package that simplifies the configuration of user preferences with an easy-to-use result builder syntax and a drop-in SwiftUI user interface.

## Overview

To configure settings, use the `configure` method on a ``DCSettingsManager`` instance, typically the shared singleton instance. ``DCSettingsManager`` is main-actor isolated, so call `configure` from the main actor. This method takes a closure that returns an array of ``DCSettingGroup`` instances. Each ``DCSettingGroup`` can contain multiple ``DCSetting`` instances. Settings will be stored in `UserDefaults`, `NSUbiquitousKeyValueStore` or a custom key-value store depending on how they are configured.

Once your settings are set up, you can quickly add a settings view to your app using ``DCSettingsView``. This view displays a list of all the setting groups and settings that you’ve configured using the given ``DCSettingsManager``. You can create an instance of this view and add it to your app’s view hierarchy like any other SwiftUI view.

> Note: The settings configuration and storage APIs support the package's minimum platform versions, except ``DCSettingStore/ubiquitous`` requires watchOS 9 or newer. ``DCSettingsView`` is available on iOS 14, macOS 11, tvOS 14, watchOS 7, and visionOS 2 or newer.

> Note: ``DCSettingsManager``, ``DCSetting``, the stored-value property wrappers, and the SwiftUI settings views are main-actor isolated. The lower-level ``DCSettingStore`` and ``DCKeyValueStore`` storage APIs remain actor-neutral.

DCSettings stores property-list compatible values (`Bool`, `Int`, `Double`, `String`, `Date`, and `Data`) directly in the selected backing store. Other values must conform to `Codable`; they are JSON-encoded to `Data` before storage and decoded when read back. Values that are neither property-list compatible nor `Codable` are rejected in debug builds with an assertion and are not persisted. Custom ``DCKeyValueStore`` implementations should accept `Data` values to support custom `Codable` setting types.

*Example configuration:*

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup("General") {
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
    DCSettingGroup("Appearance") {
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
