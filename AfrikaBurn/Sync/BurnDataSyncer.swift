//
//  BurnDataSyncer.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit

class BurnDataSyncer {
    
    private struct BundledData {
        static let url = Bundle.main.url(forResource: "afrikaburn2018_data", withExtension: "json")!
    }
    
    let fetcher = BurnDataFetcher()
    let store = PersistentStore()
    
    private let serialQueue = DispatchQueue(label: "BurnDataSyncer.serialQueue")
    
    private struct Defaults {
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
                let elements = self.loadBundledBurnData()
                self.store.storeElements(elements)
                Defaults.hasImportedBundledData = true
            }
        }
        serialQueue.async {
            self.fetcher.fetchData { [weak self] (result) in
                switch result {
                case .success(let response):
                    self?.handleJSONReceived(response)
                    break
                case .failed:
                    break
                }
            }
        }
    }
    
    private func handleJSONReceived(_ json: [BurnJSONElement]) {
        serialQueue.async {
            let elements = json.flatMap({ $0.toRealmObject() })
            self.store.storeElements(elements)
        }
    }
    
    private func loadBundledBurnData() -> [AfrikaBurnElement] {
        do {
            let data = try Data(contentsOf: BundledData.url)
            let response: [BurnJSONElement] = APIResponseSerializer.convertResponse(withData: data) ?? []
            return response.flatMap({ $0.toRealmObject() })
        } catch {
            assertionFailure("Failed to load bundled burn data with error \(error)")
            return []
        }
    }
}

extension BurnJSONElement {
    func toRealmObject() -> AfrikaBurnElement? {
        guard let elementType = AfrikaBurnElement.ElementType(name: type.lowercased()) else {
            assertionFailure("Unknown element type \(type)")
            return nil
        }
        guard let idInt = Int(id) else {
            assertionFailure("ID could not be converted to an Int \(id)")
            return nil
        }
        let categories = plannedActivities.components(separatedBy: ",").map({ AfrikaBurnElement.Category(name: $0) })
        return AfrikaBurnElement(id: idInt, name: title, categories: categories, longBlurb: longBlurb, shortBlurb: nil, scheduledActivities: plannedActivitiesDescription, elementType: elementType, locationString: "")
    }
}
