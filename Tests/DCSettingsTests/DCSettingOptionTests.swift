//
//  DCSettingOptionTest.swift
//  
//  Created by David Caddy on 12/5/2023.
//

import XCTest
@testable import DCSettings

final class DCSettingOptionTests: XCTestCase {

    func testInitValueTypeLosslessStringConvertible() {
        let option = DCSettingOption(value: 1)
        XCTAssertEqual(option.value, 1)
        XCTAssertEqual(option.label, "1")
        XCTAssertNil(option.image)
        XCTAssertNil(option.systemImage)
        XCTAssertFalse(option.isDefault)
    }

    func testInitValueLabel() {
        let option = DCSettingOption(value: 1, label: "One")
        XCTAssertEqual(option.value, 1)
        XCTAssertEqual(option.label, "One")
        XCTAssertNil(option.image)
        XCTAssertNil(option.systemImage)
        XCTAssertFalse(option.isDefault)
    }

    func testInitValueImage() {
        let option = DCSettingOption(value: 1, image: "image")
        XCTAssertEqual(option.value, 1)
        XCTAssertNil(option.label)
        XCTAssertEqual(option.image, "image")
        XCTAssertNil(option.systemImage)
        XCTAssertFalse(option.isDefault)
    }

    func testInitValueSystemImage() {
        let option = DCSettingOption(value: 1, systemImage: "systemImage")
        XCTAssertEqual(option.value, 1)
        XCTAssertNil(option.label)
        XCTAssertNil(option.image)
        XCTAssertEqual(option.systemImage, "systemImage")
        XCTAssertFalse(option.isDefault)
    }

    func testInitValueLabelImage() {
        let option = DCSettingOption(value: 1, label: "One", image: "image")
        XCTAssertEqual(option.value, 1)
        XCTAssertEqual(option.label, "One")
        XCTAssertEqual(option.image, "image")
        XCTAssertNil(option.systemImage)
        XCTAssertFalse(option.isDefault)
    }

    func testInitValueLabelSystemImage() {
        let option = DCSettingOption(value: 1, label: "One", systemImage: "systemImage")
        XCTAssertEqual(option.value, 1)
        XCTAssertEqual(option.label, "One")
        XCTAssertNil(option.image)
        XCTAssertEqual(option.systemImage, "systemImage")
        XCTAssertFalse(option.isDefault)
    }
}
