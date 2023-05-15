//
//  File.swift
//  
//
//  Created by Dave Caddy on 13/5/2023.
//

import XCTest
@testable import DCSettings

final class DCSettingTests: XCTestCase {

    func testInit() {
        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: nil, store: nil)

        XCTAssertEqual(setting.key, "key")
        XCTAssertEqual(setting.value, 1)
        XCTAssertEqual(setting.label, "label")
    }

    func testInitWithDefaultValue() {
        let setting = DCSetting(key: "key", defaultValue: 2, label: "label", store: nil)

        XCTAssertEqual(setting.value, 2)
    }

    func testInitWithOptions() {
        let options = [
            DCSettingOption(value: 1, label: "1"),
            DCSettingOption(value: 2, label: "2"),
            DCSettingOption(value: 3, label: "3")
        ]

        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: .init(options: options, bounds: nil, step: nil), store: nil)

        XCTAssertEqual(setting.configuation?.options, options)
    }

    func testInitWithBounds() {
        let bounds = DCValueBounds(lowerBound: 1, upperBound: 3)

        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: .init(options: nil, bounds: bounds, step: nil), store: nil)

        XCTAssertEqual(setting.configuation?.bounds, bounds)
    }

    func testInitWithStep() {
        let step = 1

        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: .init(options: nil, bounds: nil, step: step), store: nil)

        XCTAssertEqual(setting.configuation?.step, step)
    }

    func testRefresh() {
        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: nil, store: nil)

        setting.refresh()

        XCTAssertEqual(setting.value, 1)
    }

    func testSet() {
        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: nil, store: .standard)
        
        setting.value = 2

        XCTAssertEqual(setting.store?.object(forKey: "key"), 2)
    }

    func testValueBinding() {
        let setting = DCSetting(key: "key", value: 1, label: "label", configuation: nil, store: nil)

        let binding = setting.valueBinding()

        XCTAssertEqual(binding.wrappedValue, 1)

        binding.wrappedValue = 2

        XCTAssertEqual(setting.value, 2)
    }

}
