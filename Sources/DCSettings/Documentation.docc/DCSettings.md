# ``DCSettings``

DCSettings is a Swift package that simplifies user preference configuration with a result builder syntax and a drop-in SwiftUI settings UI for iOS, macOS, watchOS, and visionOS.

## Overview

Call `configure` on a ``DCSettingsManager`` (typically the shared singleton) from the main actor. The closure returns an array of ``DCSettingGroup`` instances, each containing one or more ``DCSetting`` instances. Settings are persisted in `UserDefaults`, `NSUbiquitousKeyValueStore`, or a custom key-value store depending on the configured ``DCSettingStore``.

Configure a manager before presenting ``DCSettingsView`` or constructing ``DCStoredValue`` and ``DCStoredRepresentedValue`` wrappers. Calling `configure` again replaces the manager's lookup state, but views and stored-value wrappers that were already created keep observing their original setting instances.

Once settings are configured, drop a ``DCSettingsView`` into your app on iOS, macOS, watchOS, or visionOS. The view lists every group and setting managed by the given ``DCSettingsManager`` and behaves like any other SwiftUI view.

> Note: The settings configuration and storage APIs support the package's minimum platform versions, except ``DCSettingStore/ubiquitous`` requires watchOS 9 or newer. ``DCSettingView``, ``DCSettingsView``, and ``DCSettingViewProviding`` are not available on tvOS in 1.0.

> Note: In the default watchOS settings UI, `Date` settings are editable with SwiftUI's date picker on watchOS 10 or newer and display-only on earlier watchOS versions. `Color` settings are display-only on watchOS.

> Note: ``DCSettingsManager``, ``DCSetting``, the stored-value property wrappers, and the SwiftUI settings views are main-actor isolated. The lower-level ``DCSettingStore`` and ``DCKeyValueStore`` storage APIs remain actor-neutral and `Sendable`, so custom stores must be safe to pass across concurrency domains.

### Storage

DCSettings stores property-list compatible values (`Bool`, `Int`, `Double`, `String`, `Date`, and `Data`) directly in the selected backing store. Other `Codable` values are JSON-encoded to `Data` before storage and decoded when read back.

On platforms with UIKit or AppKit, including watchOS, RGB-resolvable `Color` values are stored as JSON-encoded RGBA component `Data`. Dynamic, semantic, asset catalog, pattern, and other non-RGB-resolvable colors may not persist, and stored colors do not preserve named or dynamic color semantics. Persist a custom `Codable` token or enum when you need stable named themes, semantic colors, dynamic colors, or asset colors. On watchOS, the default settings UI displays `Color` values without editing.

``DCSetting`` value types must be non-optional; model unset, inherited, or system-default states with a concrete default value or an explicit enum case. Values that are neither property-list compatible nor a supported RGB-resolvable `Color` or `Codable` value are rejected in debug builds with an assertion and are not persisted. Custom ``DCKeyValueStore`` implementations should be `Sendable` and accept `Data` values to support custom `Codable` setting types.

``DCSettingStore/set(_:forKey:)`` returns `true` when DCSettings accepts a value, encodes it if needed, and submits it to an available backing store. It does not guarantee durable persistence because ``DCKeyValueStore`` setters follow `UserDefaults` and `NSUbiquitousKeyValueStore` by not reporting write failures. Custom backing-store failures are therefore assumed successful once the setter returns.

Each group can provide a backing store, and each ``DCSetting`` can provide a per-setting override. When a setting's store is `nil`, the manager resolves the inherited group store at configuration time without changing the setting itself, so a reused setting placed under a different group store picks up the new inherited store. Custom ``DCSettable`` conformers do not get that non-mutating inherited-store behavior automatically; if a custom conformer's `store` is `nil`, ``DCSettingsManager`` assigns the containing group store to the conformer during configuration.

### Keys and validation

Group keys and setting keys must be unique across all groups configured in a ``DCSettingsManager``. `DCSettingGroup("General")` uses `"General"` as both the group label and group key. Prefer ``DCSettingGroup/init(key:label:store:settings:)`` when the key is persisted, filtered, localized, or otherwise part of app behavior. `DCSettingGroup()` uses a generated key and is best reserved for groups that never need stable identity.

Configured options and comparable bounds are validated when a ``DCSetting`` is initialized, written, or refreshed. Option values must be unique, and values outside the configured option list or bounds are ignored. The configuration `step` value is a positive-increment hint for editing controls; bounded ``DCSetting`` initializers reject non-positive or non-finite step values. In the default settings UI, unbounded `Double` settings use numeric text entry and bounded numeric settings use sliders.

The default settings UI renders controls for `Bool`, `Int`, `Double`, `String`, `Date`, and `Color`. It renders `options` for `Int`, `Double`, and `String`; `bounds` for `Int`, `Double`, and `Date`; and `step` for `Int` controls and bounded `Double` sliders. Other configuration combinations and custom value types still validate values, but the built-in UI does not render controls for them. Use ``DCSettingViewProviding`` when you need custom UI for those combinations.

### Migrating to 1.0

DCSettings 1.0 stabilizes the public API and includes source-breaking changes from 0.3.x:

- Replace `configuation` with ``DCSettable/configuration``. The old spelling remains as a deprecated compatibility alias for reads.
- Custom ``DCSettable`` conformers must provide ``DCSettable/configuration``.
- ``DCSettable/set(_:)`` returns `Bool` for writes that need a success result. A default implementation is provided, but custom conformers that persist values should override it.
- ``DCSetting`` preserves `store == nil` as a reusable inherited-store state. Custom ``DCSettable`` conformers with `store == nil` are assigned the containing group store during configuration, so reusable custom conformers should model explicit versus inherited storage themselves if that distinction matters.
- ``DCStoredValue`` and ``DCStoredRepresentedValue`` require concrete ``DCSetting`` instances. Custom ``DCSettable`` conformers remain supported through manager accessors, bindings, publishers, and settings views.
- `DCSettingStore.set(_:forKey:)` overloads return `Bool` when DCSettings accepts and submits a write. This does not guarantee durable persistence; custom ``DCKeyValueStore`` failures are assumed successful once the backing-store setter returns.
- ``DCKeyValueStore`` now requires `Sendable`; custom stores should be thread-safe or explicitly audited.
- ``DCSetting`` value types must be non-optional, and bounded defaults must satisfy configured options and bounds.
- Setting option values must be unique.
- Numeric bounded settings now require `ValueType: Numeric & Comparable`.
- Unbounded `Double` settings use numeric text entry in the default settings UI. Define bounds when you want a slider.
- ``DCSettingsView/Filter`` now separates group and setting filtering. Use `.excludeGroups(_:)`, `.excludeSettings(_:)`, or `.exclude(groupKeys:settingKeys:)` instead of the old combined `.excludeKeys(_:)` case.
- `Color` no longer conforms to `Codable` through DCSettings. RGB-resolvable colors are stored internally as RGBA components on platforms with UIKit or AppKit.
- ``DCSettingView``, ``DCSettingsView``, and ``DCSettingViewProviding`` are unavailable on tvOS in 1.0.
- ``DCStoredValue``, ``DCStoredRepresentedValue``, ``DCSettingView``, and ``DCSettingsView`` expose their main-actor isolation directly in Swift 6. Use them from the main actor.
- The fully generic `DCSettingsView(settingsManager:filter:contentProvider:listStyle:)` initializer no longer supplies default `contentProvider` or `listStyle` arguments. Use one of the convenience initializers when you want the package's default provider and platform list style.
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
        DCSetting(key: "highlightColor", defaultValue: Color.blue)
    }
}
```

*Corresponding settings view:*

![Settings View](SettingsView.png)

```swift
DCSettingsView()
```
