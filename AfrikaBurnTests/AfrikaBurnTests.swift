//
//  AfrikaBurnTests.swift
//  AfrikaBurnTests
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import XCTest
@testable import AfrikaBurn
import RealmSwift
import CoreLocation

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
    
    func testNearbyQuery() {
        let p = PersistentStore()
        let predicate = NSPredicate(format: "locationString != nil")
//        guard let userLocation = LocationManager.sharedInstance.usersCurrentLocation else {
//            XCTFail("user location unknown")
//            return
//        }
        
        let userLocation = CLLocation(latitude: -32.327128337466945, longitude: 19.74432262601431)
        let filteredElements = p.elements().filter(predicate).sorted { (e1, e2) -> Bool in
            return e1.location!.distance(from: userLocation) < e2.location!.distance(from: userLocation)
        }
        XCTAssertTrue(filteredElements.count > 0)
    }
}
