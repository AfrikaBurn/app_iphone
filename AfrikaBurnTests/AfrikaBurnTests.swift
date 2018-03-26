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
    
    func testDataFetcher() {
        let fetcher = BurnDataFetcher()
        
        let expectation = self.expectation(description: "waiting for fetch")
        fetcher.fetchData { [weak expectation] (result) in
            switch result {
            case .failed: XCTFail("Network call failed")
            case .success(let elements):
                XCTAssertTrue(elements.count > 0)
                break
            }
            expectation?.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
