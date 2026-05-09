# ``DCSettings``

DCSettings is a Swift package that simplifies the configuration of user preferences with an easy-to-use result builder syntax and a drop-in SwiftUI settings UI for iOS, macOS, watchOS, and visionOS.

## Overview

To configure settings, use the `configure` method on a ``DCSettingsManager`` instance, typically the shared singleton instance. ``DCSettingsManager`` is main-actor isolated, so call `configure` from the main actor. This method takes a closure that returns an array of ``DCSettingGroup`` instances. Each ``DCSettingGroup`` can contain multiple ``DCSetting`` instances. Settings will be stored in `UserDefaults`, `NSUbiquitousKeyValueStore` or a custom key-value store depending on how they are configured.

Configure a manager before presenting ``DCSettingsView`` or constructing ``DCStoredValue`` and ``DCStoredRepresentedValue`` wrappers. Calling `configure` again replaces manager lookup state, but already-created views and stored-value wrappers keep observing the setting instances they were created with.

Once your settings are set up, you can quickly add a settings view to your app using ``DCSettingsView`` on iOS, macOS, watchOS, and visionOS. This view displays a list of all the setting groups and settings that you’ve configured using the given ``DCSettingsManager``. You can create an instance of this view and add it to your app’s view hierarchy like any other SwiftUI view.

> Note: The settings configuration and storage APIs support the package's minimum platform versions, except ``DCSettingStore/ubiquitous`` requires watchOS 9 or newer. ``DCSettingView``, ``DCSettingsView``, and ``DCSettingViewProviding`` are not available on tvOS in 1.0.

> Note: In the default watchOS settings UI, `Date` settings are editable with SwiftUI's date picker on watchOS 10 or newer and display-only on earlier watchOS versions. `Color` settings are display-only on watchOS.

> Note: ``DCSettingsManager``, ``DCSetting``, the stored-value property wrappers, and the SwiftUI settings views are main-actor isolated. The lower-level ``DCSettingStore`` and ``DCKeyValueStore`` storage APIs remain actor-neutral and `Sendable`; custom stores must be safe to pass across concurrency domains.

DCSettings stores property-list compatible values (`Bool`, `Int`, `Double`, `String`, `Date`, and `Data`) directly in the selected backing store. On platforms with UIKit or AppKit, RGB-resolvable `Color` values are handled as a built-in type and stored as JSON-encoded RGBA component `Data`; on watchOS, the default settings UI displays `Color` values without editing and built-in `Color` storage is not available. Dynamic, semantic, asset catalog, pattern, or otherwise non-RGB-resolvable colors may not persist, and stored colors do not preserve named or dynamic color semantics. Persist a custom `Codable` token or enum when you need stable named themes, semantic colors, dynamic colors, or asset colors. Other values must conform to `Codable`; they are JSON-encoded to `Data` before storage and decoded when read back. ``DCSetting`` value types must be non-optional; model unset, inherited, or system-default states with a concrete default value or an explicit enum case. Values that are neither property-list compatible nor a supported RGB-resolvable `Color` or `Codable` value are rejected in debug builds with an assertion and are not persisted. Custom ``DCKeyValueStore`` implementations should be `Sendable` and accept `Data` values to support custom `Codable` setting types.

Group keys and setting keys must be unique across all groups configured in a ``DCSettingsManager``. `DCSettingGroup("General")` uses `"General"` as both the group label and group key. Prefer ``DCSettingGroup/init(key:label:store:settings:)`` when the key is persisted, filtered, localized, or otherwise part of app behavior. `DCSettingGroup()` uses a generated key and is best reserved for groups that never need stable identity.

Configured options and comparable bounds are treated as validation rules when a ``DCSetting`` is initialized, written, or refreshed. Option values must be unique, and values outside the configured option list or bounds are ignored. The configuration `step` value is used by editing controls as a positive increment hint; bounded ``DCSetting`` initializers reject non-positive or non-finite step values. In the default settings UI, unbounded `Double` settings use numeric text entry, while bounded numeric settings use sliders.

### Migrating to 1.0

DCSettings 1.0 stabilizes the public API and includes source-breaking changes from 0.3.x:

- Replace `configuation` with ``DCSettable/configuration``. The old spelling remains as a deprecated compatibility alias for reads.
- Custom ``DCSettable`` conformers must provide ``DCSettable/configuration``.
- `DCSettingStore.set(_:forKey:)` returns `Bool`; check the return value when persistence failure matters.
- ``DCKeyValueStore`` now requires `Sendable`; custom stores should be thread-safe or explicitly audited.
- ``DCSetting`` value types must be non-optional, and bounded defaults must satisfy configured options and bounds.
- Setting option values must be unique.
- Numeric bounded settings now require `ValueType: Numeric & Comparable`.
- Unbounded `Double` settings use numeric text entry in the default settings UI. Define bounds when you want a slider.
- ``DCSettingsView/Filter`` now separates group and setting filtering. Use `.excludeGroups(_:)`, `.excludeSettings(_:)`, or `.exclude(groupKeys:settingKeys:)` instead of the old combined `.excludeKeys(_:)` case.
- `Color` no longer conforms to `Codable` through DCSettings. RGB-resolvable colors are stored internally as RGBA components on platforms with UIKit or AppKit.
- ``DCSettingView``, ``DCSettingsView``, and ``DCSettingViewProviding`` are unavailable on tvOS in 1.0.
- ``DCStoredValue``, ``DCStoredRepresentedValue``, ``DCSettingView``, and ``DCSettingsView`` expose their main-actor isolation directly in Swift 6. Use them from the main actor.
- The fully generic `DCSettingsView(settingsManager:filter:contentProvider:listStyle:)` initializer no longer supplies default `contentProvider` or `listStyle` arguments. Use the platform-default convenience initializers when you want package defaults.
- `DCSettingOption.labelView()` and `Text.monospacedDigitIfAvailable()` are internal implementation details in 1.0.

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
        #if !os(watchOS)
        DCSetting(key: "highlightColor", defaultValue: Color.blue)
        #endif
    }
}
```

*Corresponding settings view:*

![Settings View](SettingsView.png)

```swift
DCSettingsView()
```
