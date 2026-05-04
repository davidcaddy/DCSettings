# Changelog

## 1.0.0 - Unreleased

DCSettings 1.0 stabilizes the public API after the beta period.

### Requirements

- Requires Swift 6.0 or newer.
- Supports iOS 14, macOS 11, tvOS 14, watchOS 7, and visionOS 2 or newer.
- `DCSettingStore.ubiquitous` requires watchOS 9 or newer.

### Highlights

- Adds `configuration` as the correctly spelled setting configuration property.
- Keeps the misspelled `configuation` property as deprecated compatibility API.
- Builds in Swift 6 language mode with explicit main-actor isolation for the settings UI state layer.
- Emits current values immediately from manager value publishers.
- Supports Codable setting values by storing them as JSON-encoded `Data`.
- De-duplicates unchanged UserDefaults publisher values and ignores unrelated ubiquitous-store key changes.
- Refines default settings controls, option pickers, date ranges, and platform list styles.
- Expands package tests around storage, publishers, setting views, options, and string formatting.

### Migration Notes

- If you previously read `configuation`, move to `configuration`.
- Custom `DCKeyValueStore` implementations should accept `Data` values to support custom Codable setting types.
- Values that are neither property-list compatible nor `Encodable` are not persisted.
