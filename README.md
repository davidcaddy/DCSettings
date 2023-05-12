# DCSettings

DCSettings is a Swift package designed to help manage user preferences. It provides an interface that allows you to easily configure settings for your app.

## Installation

To install DCSettings, add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/davidcaddy/DCSettings.git", from: "1.0.0")
]
```
## Usage

To use DCSettings, first import it into your project:

Then, configure your settings using the `DCSettingsManager.shared.configure` method:

```swift
DCSettingsManager.shared.configure {
    DCSettingGroup(key: "G1") {
        DCSetting(key: "Test", defaultValue: "")
        DCSetting(key: "Test0", store: .standard) {
            DCSettingOption(value: "Woo")
            DCSettingOption(value: "Umm", label: "Peanut", default: true)
            DCSettingOption(value: "Yo")
            DCSettingOption(value: "Hmmy", label: "Test", systemImage: "folder")
        }
        DCSetting(key: "Test2", defaultValue: false)
        DCSetting(key: "Test3", defaultValue: 1)
        DCSetting(key: "Test4", defaultValue: 0.0)
        DCSetting(key: "Test55", defaultValue: FooEnum.three)
    }
    .store(.standard)

    DCSettingGroup("Second") {
        DCSetting(key: TestKey.one, defaultValue: false)
        DCSetting(key: "Test6", defaultValue: false)
        DCSetting(key: "Test7", defaultValue: Date())
        DCSetting(key: "Test8", options: [1, 2, 3, 4], defaultIndex: 0)
        DCSetting(key: "Test9", options: ["A", "B", "C", "D"], defaultIndex: 0)
        DCSetting(key: "Test11", defaultValue: 1, lowerBound: 0, upperBound: 10, step: 2)
        DCSetting(key: "Test12", defaultValue: 1.0, lowerBound: 0, upperBound: 10)
        DCSetting(key: "Test13", defaultValue: 1.0, lowerBound: 0, upperBound: 10, step: 1)
        DCSetting(key: "Test10") {
            DCSettingOption(value: TestEnum.one.rawValue)
            DCSettingOption(value: TestEnum.two.rawValue, label: "Peanut", default: true)
            DCSettingOption(value: TestEnum.three.rawValue, systemImage: "folder")
        }
        DCSetting(key: "Test14", defaultValue: Color.red)
    }
}
```

## Notes

DCSettings supports the following types by default:

- Bool
- Int
- Double
- String
- Date
- Color (SwiftUI)

