//
//  DCSettings
//  Copyright (c) David Caddy 2023
//  MIT license, see LICENSE file for details
//

import XCTest
@testable import DCSettings

final class DCSettingTests: XCTestCase {

    private var store: DCSettingStore!
    private var backingStore: MockStore!
    private var setting: DCSetting<String>!
    
    override func setUp() {
        super.setUp()
        backingStore = MockStore()
        store = .custom(backingStore: backingStore)
        setting = DCSetting(key: "testKey", defaultValue: "defaultValue", store: store)
    }
    
    func testInitWithDefaultValue() {
        XCTAssertEqual(setting.value, "defaultValue")
    }
    
    func testValueChange() {
        setting.value = "newValue"
        
        XCTAssertEqual(setting.value, "newValue")
    }
    
    func testRefresh() {
        backingStore.set("anotherValue", forKey: "testKey")
        setting.refresh()
        
        XCTAssertEqual(setting.value, "anotherValue")
    }
    
    func testInitWithOptions() {
        let options = ["option1", "option2", "option3"]
        let setting = DCSetting(key: "testKey", store: store, options: options, defaultIndex: 1)
        
        XCTAssertEqual(setting?.value, "option2")
    }

    func testInitWithBounds() {
        let setting = DCSetting(key: "testKey", defaultValue: 5, store: store, lowerBound: 0, upperBound: 10)
        
        XCTAssertEqual(setting.value, 5)
        XCTAssertEqual(setting.configuation?.bounds, DCValueBounds(lowerBound: 0, upperBound: 10))
    }

    func testValueBinding() {
        let binding = setting.valueBinding()
        binding.wrappedValue = "newValue"
        
        XCTAssertEqual(setting.value, "newValue")
    }
    
    func testStoreSet() {
        setting.value = "newValue"
        
        XCTAssertEqual(backingStore?.storage["testKey"] as? String, setting.value)
    }
}
