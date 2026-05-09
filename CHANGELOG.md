# Changelog

## 1.0.0 - 2026-05-08

DCSettings 1.0 stabilizes the public API after the beta period.

### Requirements

- Requires Swift 6.0 or newer.
- Supports iOS 14, macOS 11, tvOS 14, watchOS 7, and visionOS 2 or newer.
- `DCSettingView`, `DCSettingsView`, and the default SwiftUI settings UI are available on iOS, macOS, watchOS, and visionOS, but not tvOS.
- `DCSettingStore.ubiquitous` requires watchOS 9 or newer.

### Highlights

- Adds `configuration` as the correctly spelled setting configuration property.
- Keeps the misspelled `configuation` property as deprecated compatibility API.
- Adds public initializers for `DCSettingConfiguration` and `DCValueBounds`.
- Enforces configured options and comparable bounds when settings are written or refreshed.
- Rejects duplicate setting option values.
- Rejects non-positive and non-finite bounded-setting step values.
- Supports public `DCSettable` conformers in manager accessors and default supported-type settings views.
- Builds in Swift 6 language mode with explicit main-actor isolation for manager, setting, property-wrapper, and settings-view APIs.
- Emits current values immediately from manager value publishers.
- Supports Codable setting values by storing them as JSON-encoded `Data`.
- Supports RGB-resolvable Color setting values on platforms with UIKit or AppKit by storing RGBA components.
- Uses native `NSUbiquitousKeyValueStore` integer storage for ubiquitous `Int` settings.
- Fails loudly instead of falling back to `.standard` when a named `UserDefaults` suite cannot be created.
- De-duplicates unchanged UserDefaults publisher values and ignores unrelated ubiquitous-store key changes.
- Adds `if`/`switch`/`for` control-flow support to settings result builders.
- Refines default settings controls, option pickers, date ranges, and platform list styles.
- Uses numeric text entry for unbounded `Double` settings and sliders only for bounded numeric settings.
- Migrates the package test suite to Swift Testing and expands coverage around storage, publishers, setting views, options, and string formatting.

### Migration Notes

- If you previously read `configuation`, move to `configuration`.
- Custom `DCSettable` conformers must provide `configuration`.
- `DCSettingStore.set(_:forKey:)` now returns `Bool` to indicate whether the value was persisted.
- `Color` no longer conforms to `Codable` publicly through DCSettings. RGB-resolvable colors are stored internally as RGBA components on platforms with UIKit or AppKit; persist a custom `Codable` token or enum for stable named themes, semantic colors, dynamic colors, or asset colors.
- `DCSettingOption.labelView()` is now internal. Use the option's public `label` and `image` properties, or provide custom option UI through your own views.
- `DCSettingView`, `DCSettingsView`, and `DCSettingViewProviding` are not available on tvOS in 1.0. The core settings and storage APIs still support tvOS.
- Configure, read, and write settings through `DCSettingsManager` from the main actor.
- `DCStoredValue`, `DCStoredRepresentedValue`, `DCSettingView`, and `DCSettingsView` now expose their main-actor isolation directly in Swift 6. If you use them from nonisolated or background contexts, hop to the main actor first.
- Custom `DCKeyValueStore` implementations should accept `Data` values to support custom Codable setting types.
- `DCSetting` value types must be non-optional. Model unset, inherited, or system-default states with a concrete default value or an explicit enum case.
- Bounded defaults must satisfy their configured bounds.
- Numeric bounded settings now require `ValueType: Numeric & Comparable`. This matches the new bounds validation behavior and may affect custom numeric-like types.
- Group keys and setting keys must be unique across configured groups.
- Setting option values must be unique.
- `DCSettingGroup("Label")` now uses the label as the group key. Prefer `DCSettingGroup(key:label:)` when the key is persisted, filtered, localized, or otherwise part of app behavior.
- `DCSettingsView.Filter` now separates `.excludeGroups(_:)` and `.excludeSettings(_:)`; use `.exclude(groupKeys:settingKeys:)` to hide both.
- The fully generic `DCSettingsView(settingsManager:filter:contentProvider:listStyle:)` initializer no longer provides default values for `contentProvider` or `listStyle`. Use `DCSettingsView()`, `DCSettingsView(filter:)`, `DCSettingsView(contentProvider:)`, or `DCSettingsView(listStyle:)` when you want the package defaults.
- `DCDefaultViewProvider.content(for:)` now returns `EmptyView?`. If you used this concrete provider directly, treat it as a nil-only placeholder.
- The package no longer exposes `Text.monospacedDigitIfAvailable()` as public API. Use SwiftUI's `monospacedDigit()` with your own availability guard if you need the same behavior in app code.
- Values that are neither property-list compatible nor a supported RGB-resolvable `Color` or `Codable` value are not persisted.
