//
//  BurnDataSyncer.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit

class BurnDataSyncer {
    
    let fetcher = BurnDataFetcher()
    let store = PersistentStore()
    
    let serialQueue = DispatchQueue(label: "BurnDataSyncer.serialQueue")
    
    struct Defaults {
        static let hasImportedBundledDataKey = "za.co.afrikaburn.burndatasyncer.hasImportedBundledDataKey"
        static var hasImportedBundledData: Bool {
            get {
                return UserDefaults.standard.bool(forKey: hasImportedBundledDataKey)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: hasImportedBundledDataKey)
            }
        }
    }
    
    func syncData() {
        serialQueue.async {
            if Defaults.hasImportedBundledData == false {
                let elements = BurnElementsCSVParser().parseSync()
                self.store.storeElements(elements)
                Defaults.hasImportedBundledData = true
            }
        }
        serialQueue.async {
            self.fetcher.fetchData { [weak self] (result) in
                switch result {
                case .success(let response):
                    self?.handleCSVReceived(response)
                case .failed:
                    break
                }
            }
        }
    }
    
    func handleCSVReceived(_ csv: String) {
        serialQueue.async {
            let parser = BurnElementsCSVParser(parserType: .downloadedCSV(csv))
            let elements = parser.parseSync()
            self.store.storeElements(elements)
        }
    }
}
