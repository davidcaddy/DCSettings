# ``DCSettings``

DCSettings is a Swift package that simplifies the configuration of user preferences with an easy-to-use result builder syntax and a drop-in SwiftUI user interface.

## Overview

To configure settings, you can use the `configure` method on a ``DCSettingsManager`` instance, typically the shared  singleton instance. This method takes a closure that returns an array of ``DCSettingGroup`` instances. Each ``DCSettingGroup`` can contain multiple ``DCSetting`` instances. Settings will be stored in `UserDefaults`, `NSUbiquitousKeyValueStore` or a custom key-value store depending on how they are configured. 

Once your settings are set up, you can quickly add a settings view to your app using ``DCSettingsView``. This view displays a list of all the setting groups and settings that you’ve configured using the given ``DCSettingsManager``. You can create an instance of this view and add it to your app’s view hierarchy like any other SwiftUI view.

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
        DCSetting(key: "theme", label: "Theme", options: ["Light", "Dark"], defaultIndex: 0)
        DCSetting(key: "fontSize", options: [12, 14, 16, 18, 20], defaultIndex: 2)
        DCSetting(key: "lineSpacing", defaultValue: 1.2, lowerBound: 1.0, upperBound: 1.6, step: 0.1)
        DCSetting(key: "highlightColor", defaultValue: Color.blue)
    }
}
```

*Corresponding settings view:*

![Settings View](SettingsView.png)

```swift
DCSettingsView(includeSettingsWithoutLabels: true)
```
