//
//  AfrikaBurnTests.swift
//  AfrikaBurnTests
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import XCTest
@testable import AfrikaBurn

class AfrikaBurnTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCSVParsing() {
        let parser = ThemeCampCSVParser()
        let res = parser.parseSync()
        XCTAssertTrue(res.count > 0)
    }    
}
