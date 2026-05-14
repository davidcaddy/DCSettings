<p align="center">
    <img src="Logo.png" width="190" max-width="20%" alt="DCSettings" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/Swift-6.0-orange.svg" />
    <a href="https://swift.org/package-manager">
        <img src="https://img.shields.io/badge/swiftpm-compatible-brightgreen.svg?style=flat" alt="Swift Package Manager" />
    </a>
     <img src="https://img.shields.io/badge/platforms-iOS+macOS+tvOS+watchOS+visionOS-brightgreen.svg?style=flat" alt="iOS | macOS | tvOS | watchOS | visionOS" />
    <a href="https://mastodon.social/@caddy">
        <img src="https://img.shields.io/badge/Mastodon-@caddy-blue.svg?style=flat" alt="Mastodon: @caddy" />
    </a>
</p>

Welcome to **DCSettings**, a Swift package that simplifies user preference configuration with a result builder syntax and a drop-in SwiftUI settings UI for iOS, macOS, watchOS, and visionOS.

You can configure settings backed by `UserDefaults`, `NSUbiquitousKeyValueStore`, or a custom key-value store:

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

Then use a **DCSettingsView** to display the settings in a list view:

![Settings View](/Sources/DCSettings/Documentation.docc/Resources/SettingsView.png#gh-light-mode-only)
![Settings View](/Sources/DCSettings/Documentation.docc/Resources/SettingsView~dark.png#gh-dark-mode-only)

```swift
DCSettingsView()
```

## Installation

To install **DCSettings**, add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/davidcaddy/DCSettings.git", from: "1.0.0")
]
```

### Requirements

DCSettings requires Swift 6.0 or newer and supports iOS 14, macOS 11, tvOS 14, watchOS 7, and visionOS 2 or newer.

The settings configuration and storage APIs are available on every supported platform. `DCSettingView`, `DCSettingsView`, and the default SwiftUI settings UI are not available on tvOS in 1.0. `DCSettingStore.ubiquitous` requires watchOS 9 or newer.

`DCSettingsManager`, `DCSetting`, the stored-value property wrappers, and the SwiftUI settings views are main-actor isolated; configure, read, and write settings from the main actor. The lower-level `DCSettingStore` and `DCKeyValueStore` storage APIs remain actor-neutral and `Sendable`, so custom `DCKeyValueStore` implementations must also be safe to pass across concurrency domains.

Configure a `DCSettingsManager` before presenting `DCSettingsView` or constructing `DCStoredValue` and `DCStoredRepresentedValue` wrappers. Calling `configure` again replaces the manager's lookup state, but views and stored-value wrappers that were already created keep observing their original setting instances.

### Migration Notes

- Replace any reads of `configuation` with `configuration`.
- `DCSettable` conformers must now provide `configuration`.
- `DCSettable` now includes `set(_:) -> Bool` for writes that need a success result. A default implementation is provided, but custom conformers that persist values should override it.
- `DCSetting` preserves `store == nil` as a reusable inherited-store state. Custom `DCSettable` conformers with `store == nil` are assigned the containing group store during configuration, so reusable custom conformers should model explicit versus inherited storage themselves if that distinction matters.
- `DCStoredValue` and `DCStoredRepresentedValue` require concrete `DCSetting` instances. Custom `DCSettable` conformers remain supported through manager accessors, bindings, publishers, and settings views.
- `DCSettingStore.set(_:forKey:)` overloads now return `Bool` to indicate whether the value was persisted.
- `DCKeyValueStore` now requires `Sendable`; custom stores should be thread-safe or explicitly audited.
- `Color` no longer conforms to `Codable` publicly through DCSettings. RGB-resolvable colors are stored internally as RGBA components on platforms with UIKit or AppKit.
- `DCSettingOption.labelView()` is internal in 1.0. Use the option's public `label` and `image` properties, or provide custom option UI through your own views.
- `DCSettingView`, `DCSettingsView`, and `DCSettingViewProviding` are not available on tvOS in 1.0. The core settings and storage APIs still support tvOS.
- `DCStoredValue`, `DCStoredRepresentedValue`, `DCSettingView`, and `DCSettingsView` now expose their main-actor isolation directly in Swift 6. Use them from the main actor.
- `DCSetting` value types must be non-optional, and bounded defaults must satisfy their configured bounds.
- Bounded numeric settings now require `ValueType: Numeric & Comparable`.
- Unbounded `Double` settings now use numeric text entry in the default settings UI. Define bounds when you want a slider.
- Group keys and setting keys must be unique across configured groups.
- Setting option values must be unique.
- `DCSettingGroup("Label")` now uses the label as the group key. Prefer `DCSettingGroup(key:label:)` when the key is persisted, filtered, localized, or otherwise part of app behavior.
- `DCSettingsView.Filter` now separates `.excludeGroups(_:)` and `.excludeSettings(_:)`; use `.exclude(groupKeys:settingKeys:)` to hide both.
- The fully generic `DCSettingsView(settingsManager:filter:contentProvider:listStyle:)` initializer no longer supplies default `contentProvider` or `listStyle` arguments. Use one of the convenience initializers — `DCSettingsView()`, `DCSettingsView(filter:)`, `DCSettingsView(contentProvider:)`, or `DCSettingsView(listStyle:)` — to get the default provider and platform list style.
- `DCDefaultViewProvider.content(for:)` now returns `EmptyView?`, which keeps the default provider as a nil-only placeholder.
- `Text.monospacedDigitIfAvailable()` is no longer public API. Use SwiftUI's `monospacedDigit()` with an availability check in app code if needed.

#### Updating Common 0.3.x Code

If you used the old combined settings-view filter, choose the new key type explicitly:

```swift
// 0.3.x
DCSettingsView(filter: .excludeKeys(["general"]))

// 1.0
DCSettingsView(filter: .excludeGroups(["general"]))
DCSettingsView(filter: .excludeSettings(["showNotifications"]))
DCSettingsView(filter: .exclude(groupKeys: ["general"], settingKeys: ["showNotifications"]))
```

If you set values directly through `DCSettingStore`, decide whether to handle persistence failure:

```swift
let didSave = DCSettingStore.standard.set(value, forKey: "settingKey")
```

Custom `DCSettable` conformers need the correctly spelled configuration property:

```swift
var configuration: DCSettingConfiguration<Value>? { nil }
```

## Usage

Import the module wherever you want to configure or read settings:

```swift
import DCSettings
```

## Configuring Settings

Call `configure` on a `DCSettingsManager` (typically the shared singleton) from the main actor. The closure returns an array of `DCSettingGroup` instances, each containing one or more `DCSetting` instances.

Configure the manager before creating settings UI or stored-value wrappers. Calling `configure` again replaces the manager's lookup state, but any `DCSettingsView`, `DCStoredValue`, and `DCStoredRepresentedValue` instances that already exist continue to observe their original setting objects.

Example configuration:

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "showNotifications", defaultValue: true)
        DCSetting(key: "soundEffects", defaultValue: true)
        DCSetting(key: "themeColor") {
            DCSettingOption(value: "Blue")
            DCSettingOption(value: "Red")
            DCSettingOption(value: "Green")
        }
    }
    .store(.standard)
    DCSettingGroup(key: "appearance", label: "Appearance") {
        DCSetting(key: "fontSize", defaultValue: 14)
        DCSetting(key: "fontName", defaultValue: "Helvetica")
    }
}
```

Use `DCSettingGroup` to group related settings under a key and a human-readable label. Group keys and setting keys must be unique across all groups configured in a `DCSettingsManager`, and group keys should be distinct from any setting key.

`DCSettingGroup("General")` uses `"General"` as both the group label and the group key. Prefer `DCSettingGroup(key:label:)` when the key is persisted, filtered, localized, or otherwise part of app behavior. `DCSettingGroup()` uses a generated key and is best reserved for groups that never need stable identity.

Each `DCSetting` has a unique key, a non-optional default value, and an optional label. The default value is used until the user (or your code) sets one. If no label is provided, a sentence-cased version of the key is used.

> Note: `DCSetting` supports non-optional values for `Bool`, `Int`, `Double`, `String`, `Date`, and `Color` (SwiftUI) by default. `Color` storage is available for RGB-resolvable colors on platforms with UIKit or AppKit. Custom non-optional `Codable` types are also supported.

`DCSettingConfiguration` exposes three additional knobs:

- **options**: a list of `DCSettingOption` values that constrain the setting. Option values must be unique, and values outside the list are ignored. Each option has a value and an optional `label` and `image`.
- **bounds**: a `DCValueBounds` lower/upper range for `Comparable` values. Values outside the range are ignored.
- **step**: a positive-increment hint for editing controls. Bounded `DCSetting` initializers reject non-positive and non-finite step values.

Example configuration using these options:

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "themeColor") {
            DCSettingOption(value: "Blue", default: true)
            DCSettingOption(value: "Red")
            DCSettingOption(value: "Green")
        }
        DCSetting(key: "fontSize", label: "Font Size") {
            DCSettingOption(value: 10, label: "10 pt")
            DCSettingOption(value: 12, label: "12 pt")
            DCSettingOption(value: 14, label: "14 pt").default()
            DCSettingOption(value: 16, label: "16 pt")
            DCSettingOption(value: 18, label: "18 pt")
            DCSettingOption(value: 20, label: "20 pt")
        }
        DCSetting(key: "lineSpacing", defaultValue: 1.2, lowerBound: 1.0, upperBound: 1.6, step: 0.1)
    }
}
```

The theme color and font size settings use explicit options, while line spacing is constrained to the range 1.0...1.6 with an editing increment of 0.1.

## Accessing Settings

Access configured settings elsewhere with the `DCStoredValue` property wrapper:

```swift
@DCStoredValue("showNotifications") var showNotifications: Bool
```

`DCStoredValue` and `DCStoredRepresentedValue` capture concrete `DCSetting` instances. If you use a custom `DCSettable` conformer, access it through `DCSettingsManager.value(forKey:)`, `set(_:forKey:)`, `valueBinding(forKey:)`, `valuePublisher(forKey:)`, or by passing it to `DCSettingView`.

You can also read settings directly through `DCSettingsManager` convenience methods:

```swift
let showNotifications = DCSettingsManager.shared.bool(forKey: "showNotifications")
```

## Backing Stores

Each setting group and individual setting can specify its own key-value store. By default, settings use the standard store backed by `UserDefaults.standard`. Use the *store* property on `DCSettingGroup` or `DCSetting` to override it.

This example uses a `UserDefaults` suite named `"com.example.myapp"`:

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "showNotifications", defaultValue: true)
    }
    .store(.userDefaults(suiteName: "com.example.myapp"))
}
```

> Note: If a group does not specify a store, the standard store is used.

A store can also be set on an individual setting:

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "showNotifications", defaultValue: true, store: .userDefaults(suiteName: "com.example.myapp"))
    }
}
```

> Note: A store set on a group is inherited by every setting in that group, unless the setting overrides it.

A `DCSetting`'s own `store` acts as an explicit override. When it is `nil`, the manager resolves the inherited group store at configuration time without changing the setting itself, so a reused `DCSetting` placed under a different group store picks up the new inherited store.

Custom `DCSettable` conformers do not get that non-mutating inherited-store behavior automatically. If a custom conformer's `store` is `nil`, `DCSettingsManager` assigns the containing group store to the conformer during configuration. Reusable custom conformers should keep their own explicit override separate from inherited storage when they need to move between groups.

### Storage contract

DCSettings stores property-list compatible values (`Bool`, `Int`, `Double`, `String`, `Date`, and `Data`) directly in the selected backing store. Other `Codable` values are JSON-encoded to `Data` before storage and decoded when read back.

On platforms with UIKit or AppKit, including watchOS, RGB-resolvable `Color` values are stored as JSON-encoded RGBA component `Data`. Dynamic, semantic, asset catalog, pattern, and other non-RGB-resolvable colors may not persist, and stored colors do not preserve named or dynamic color semantics. On watchOS, the default settings UI displays `Color` values without editing.

`DCSetting` value types must be non-optional; model unset, inherited, or system-default states with a concrete default value or an explicit enum case. Values that are neither property-list compatible nor a supported RGB-resolvable `Color` or `Codable` value are rejected in debug builds with an assertion and are not persisted.

Custom `DCKeyValueStore` implementations should accept `Data` values to support custom `Codable` setting types. They must also be `Sendable`; use internal synchronization or another concurrency-safe design when storing mutable state.

**DCSettings** also supports `NSUbiquitousKeyValueStore`, which stores values in iCloud so settings can be shared across a user's devices:

> Note: `DCSettingStore.ubiquitous` requires watchOS 9 or newer. The rest of the configuration and storage APIs support the package's minimum platform versions.

> Note: `DCSettingStore.userDefaults(suiteName:)` requires the named suite to be creatable. Invalid suite names fail loudly in debug builds instead of falling back to `.standard`.

Set `DCSETTINGS_RUN_ICLOUD_TESTS=1` when running tests to include the `NSUbiquitousKeyValueStore` integration checks.

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "general", label: "General") {
        DCSetting(key: "showNotifications", defaultValue: true)
        DCSetting(key: "soundEffects", defaultValue: true)
    }
    .store(.ubiquitous)
}
```

## DCSettingsView

Once settings are configured, drop a `DCSettingsView` into your app on iOS, macOS, watchOS, or visionOS. The view lists every group and setting managed by the given `DCSettingsManager` and behaves like any other SwiftUI view.

> Note: `DCSettingView`, `DCSettingsView`, and `DCSettingViewProviding` are unavailable on tvOS in 1.0. tvOS apps can still use the core settings and storage APIs with custom UI.

Example usage:

```swift
struct ContentView: View {
    var body: some View {
        DCSettingsView(filter: .labelled)
    }
}
```

> Note: By default, `DCSettingsView` displays **all** settings. Pass `.labelled` to show only settings that have a label.

`DCSettingsView` accepts a filter for hiding groups or individual settings, and a content provider for overriding how individual settings are displayed.

Excluding the "General" group via the filter:

```swift
struct ContentView: View {
    var body: some View {
        DCSettingsView(filter: .excludeGroups(["general"]))
    }
}
```

Use `.excludeGroups(_:)` for group keys, `.excludeSettings(_:)` for setting keys, or `.exclude(groupKeys:settingKeys:)` when you need both.

### Types

`DCSettingsView` chooses an appropriate control for each setting based on its value type and configuration:

- `Bool`: a toggle switch.
- `Int`: a segmented control or menu when options are configured, a slider when bounds are configured, or a stepper otherwise.
- `Double`: a segmented control or menu when options are configured, a slider when bounds are configured, or numeric text entry otherwise.
- `String`: a segmented control or menu when options are configured, or a text field otherwise.
- `Date`: a date picker. Date editing on watchOS requires watchOS 10 or newer; earlier watchOS versions display the current date without editing.
- `Color`: a color picker on iOS, macOS, and visionOS. On watchOS, color settings display the current color without editing. Use `Color` settings for user-selected RGB-resolvable colors; persist a custom `Codable` token or enum for stable named themes, semantic colors, dynamic colors, or asset colors.

The configuration model validates supported values for every `DCSetting`, but the default UI only renders configuration for these combinations:

| Value type | `options` UI | `bounds` UI | `step` UI |
| --- | --- | --- | --- |
| `Bool` | No | No | No |
| `Int` | Picker/menu | Slider | Stepper or slider increment |
| `Double` | Picker/menu | Slider | Bounded slider increment |
| `String` | Picker/menu | No | No |
| `Date` | No | Date picker range | No |
| `Color` | No | No | No |

Unsupported UI combinations still participate in validation. For example, a `Date` setting with options will reject values outside those options, but the built-in date picker will not render an options picker. Use `DCSettingViewProviding` for custom controls when you need UI for those combinations.

### Customization

Several `DCSetting` options affect how the setting renders inside a `DCSettingsView`:

- `label`: a human-readable name shown next to the control.
- `image`: the name of an asset-catalog image shown next to the label.
- `systemImage`: the name of an SF Symbol shown next to the label.
- `bounds`: a valid range for `Comparable` values. Numeric settings with bounds render as sliders constrained to the range.
- `step`: the positive increment used by numeric controls. It is a UI hint only — use `options` or `bounds` to validate values. Bounded initializers reject non-positive and non-finite steps, and the default controls ignore invalid step values supplied through custom configurations.

### DCSettingViewProviding

`DCSettingViewProviding` lets you supply custom views for individual settings in a `DCSettingsView`. Conform to the protocol and implement `content(for:)`, which receives a `DCSettable` and returns an optional view. Return a view to override the default; return `nil` to fall back to it.

Example provider:

```swift
struct MySettingViewProvider: DCSettingViewProviding {
    func content(for setting: any DCSettable) -> AnyView? {
        if setting.key == "showNotifications", let concreteSetting = setting as? DCSetting<Bool> {
            return AnyView(Toggle("Show Notifications", isOn: concreteSetting.valueBinding()))
        }

        return nil
    }
}
```

`MySettingViewProvider` returns a custom toggle for the `"showNotifications"` setting and `nil` for everything else, leaving the rest to the default views.

Pass an instance to `DCSettingsView` to use it:

```swift
struct ContentView: View {
    var body: some View {
        DCSettingsView(contentProvider: MySettingViewProvider())
    }
}
```

## Contributions

Bug reports and feedback are welcome. For changes, please open a Pull Request — a rough draft is fine — so the approach can be discussed before significant work goes in.
