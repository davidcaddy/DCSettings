//
//  DCValueBoundsTests.swift
//
//  Created by David Caddy on 12/5/2023.
//

import XCTest
@testable import DCSettings

final class DCValueBoundsTests: XCTestCase {

    func testEquatable() {
        let bounds1 = DCValueBounds(lowerBound: 0, upperBound: 10)
        let bounds2 = DCValueBounds(lowerBound: 0, upperBound: 10)
        let bounds3 = DCValueBounds(lowerBound: 5, upperBound: 15)
        
        XCTAssertEqual(bounds1, bounds2)
        XCTAssertNotEqual(bounds1, bounds3)
    }
    
    func testLowerBound() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        XCTAssertEqual(bounds.lowerBound, 0)
    }
    
    func testUpperBound() {
        let bounds = DCValueBounds(lowerBound: 0, upperBound: 10)
        XCTAssertEqual(bounds.upperBound, 10)
    }

}

