//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
import SwiftUI
import Combine
@testable import DCSettings

final class DCStorageConvenienceTests: XCTestCase {
    
    private enum TestMode: String {
        case list
        case grid
    }
    
    private struct ColorComponents: Codable {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables = []
        super.tearDown()
    }
    
    func testColorCodableRoundTrip() throws {
        let components = ColorComponents(red: 0.25, green: 0.5, blue: 0.75, opacity: 0.6)
        let color = Color(red: components.red, green: components.green, blue: components.blue, opacity: components.opacity)
        
        let encodedColor = try JSONEncoder().encode(color)
        let decodedColor = try JSONDecoder().decode(Color.self, from: encodedColor)
        let encodedDecodedColor = try JSONEncoder().encode(decodedColor)
        let decodedComponents = try JSONDecoder().decode(ColorComponents.self, from: encodedDecodedColor)
        
        XCTAssertEqual(decodedComponents.red, components.red, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.green, components.green, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.blue, components.blue, accuracy: 0.001)
        XCTAssertEqual(decodedComponents.opacity, components.opacity, accuracy: 0.001)
    }
    
    func testUserDefaultsValuePublisherEmitsInitialAndChangedValue() {
        let suiteName = "DCStorageConvenienceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let valueDidChange = expectation(description: "UserDefaults value changed")
        var receivedValues: [String?] = []
        
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        
        defaults.valuePublisher(forKey: "layout")
            .sink { value in
                receivedValues.append(value as? String)
                if receivedValues.count == 2 {
                    valueDidChange.fulfill()
                }
            }
            .store(in: &cancellables)
        
        defaults.set("grid", forKey: "layout")
        
        wait(for: [valueDidChange], timeout: 1.0)
        XCTAssertEqual(receivedValues, [nil, "grid"])
    }
    
    func testStoredValueReadsAndWritesConfiguredSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()
        
        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "title", defaultValue: "Initial")
            }
        }
        
        let storedValue = DCStoredValue<String>("title", settingsManager: manager)
        
        XCTAssertEqual(storedValue.wrappedValue, "Initial")
        
        storedValue.wrappedValue = "Updated"
        
        XCTAssertEqual(manager.string(forKey: "title"), "Updated")
        XCTAssertEqual(backingStore.storage["title"] as? String, "Updated")
    }
    
    func testStoredRepresentedValueReadsAndWritesRawRepresentableSetting() {
        let manager = DCSettingsManager()
        let backingStore = MockStore()
        
        manager.configure {
            DCSettingGroup("Display", store: .custom(backingStore: backingStore)) {
                DCSetting(key: "mode", defaultValue: TestMode.list.rawValue)
            }
        }
        
        let storedValue = DCStoredRepresentedValue<TestMode>("mode", settingsManager: manager)
        
        XCTAssertEqual(storedValue.wrappedValue, .list)
        
        storedValue.wrappedValue = .grid
        
        XCTAssertEqual(manager.string(forKey: "mode"), TestMode.grid.rawValue)
        XCTAssertEqual(backingStore.storage["mode"] as? String, TestMode.grid.rawValue)
        
        storedValue.wrappedValue = nil
        
        XCTAssertEqual(manager.string(forKey: "mode"), TestMode.grid.rawValue)
    }
}
