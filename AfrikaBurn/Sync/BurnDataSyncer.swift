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
        static let hasImportedBundledDataKey = "za.co.afrikaburn.burndatasyncer.hasImportedBundledDataKey.2"
        static var hasImportedBundledData: Bool {
            get {
                return UserDefaults.standard.bool(forKey: hasImportedBundledDataKey)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: hasImportedBundledDataKey)
            }
        }
        
        static let hasImportedMysteryDataKey = "za.co.afrikaburn.burndatasyncer.hasImportedMysteryData"
        static var hasImportedMysteryData: Bool {
            get {
                return UserDefaults.standard.bool(forKey: hasImportedMysteryDataKey)
            }
            set {
                UserDefaults.standard.set(newValue, forKey: hasImportedMysteryDataKey)
            }
        }
    }
    
    func shouldUseMysteryData() -> Bool {
//         return Calendar.hasAfrikaBurnStarted == false
        return false
    }
    
    func syncData() {
        guard shouldUseMysteryData() == false else {
            importMysteryData()
            // the fetcher has a cache so we want to ensure we trigger that
            // when the burn begins we will load from that cache
            fetcher.fetchData({_ in })
            return
        }
        
        // import bundled/last cached data
        serialQueue.async {
            if Defaults.hasImportedBundledData == false {
                let elements = self.loadBundledBurnData()
                self.store.storeElements(elements)
                Defaults.hasImportedBundledData = true
            }
        }
        
        // Fetch latest data if we can
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
    
    private func importMysteryData() {
        self.serialQueue.async {
            if Defaults.hasImportedMysteryData {
                return
            }
            let elements = BurnMysteryData.createMysteryData()
            self.store.storeElements(elements) {
                self.serialQueue.async {
                    Defaults.hasImportedMysteryData = true
                }
            }
        }
    }
    
    private func handleJSONReceived(_ json: [BurnJSONElement]) {
        serialQueue.async {
            let elements = json.compactMap({ $0.toRealmObject() })
            self.store.storeElements(elements)
        }
    }
    
    private func loadBundledBurnData() -> [AfrikaBurnElement] {
        let cachedElements = fetcher.cachedElements()
        if cachedElements.count > 0 {
            return cachedElements.compactMap({ $0.toRealmObject() })
        } else {
            do {
                let data = try Data(contentsOf: BundledData.url)
                let response: [BurnJSONElement] = APIResponseSerializer.convertResponse(withData: data) ?? []
                return response.compactMap({ $0.toRealmObject() })
            } catch {
                assertionFailure("Failed to load bundled burn data with error \(error)")
                return []
            }
        }
    }
}

extension BurnDataSyncer: ApplicationService {
    func startup() {
        syncData()
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidBecomeActive), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc func handleDidBecomeActive() {
        syncData()
    }
}

/*
 What we show before the event
 */
struct BurnMysteryData {
    
    struct MysteryItem {
        let title: String
        let elementType: AfrikaBurnElement.ElementType
    }
    
    private static func createMysteryItems() -> [MysteryItem] {
        return [
            MysteryItem(title: "Our lips are sealed", elementType: AfrikaBurnElement.ElementType.artwork),
            MysteryItem(title: "Mums the word", elementType: AfrikaBurnElement.ElementType.camp),
            MysteryItem(title: "We can't wait to tell you about this one!", elementType: AfrikaBurnElement.ElementType.mutantVehicle),
            MysteryItem(title: "Confidential, seek the Tankwa", elementType: AfrikaBurnElement.ElementType.performance),
            MysteryItem(title: "This one is gonna be good", elementType: AfrikaBurnElement.ElementType.artwork),
            MysteryItem(title: "Burn Burn Burn", elementType: AfrikaBurnElement.ElementType.performance),
            MysteryItem(title: "Patience is the game here", elementType: AfrikaBurnElement.ElementType.mutantVehicle),
            MysteryItem(title: "The excitement is at an all time high", elementType: AfrikaBurnElement.ElementType.camp),
        ]
    }
    
    static func createMysteryData() -> [AfrikaBurnElement] {
        var result: [AfrikaBurnElement] = []
        for (index, item) in createMysteryItems().enumerated() {
         let e = AfrikaBurnElement(id: index * -1,
                           name: item.title,
                           categories: [],
                           longBlurb: "All will be revealed when AfrikaBurn opens on the 23rd of April.",
                           shortBlurb: "Open the App when you begin the drive/flight in while you have signal to fetch the latest data",
                           scheduledActivities: nil,
                           elementType: item.elementType,
                           locationString: "")
            result.append(e)
        }
        return result
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
        
        let locations = ["-32.32893208554183,19.747913535708904",
                         "-32.32778403741981,19.74691967489298",
                         "-32.32656919940414,19.744494957943516",
                         "-32.327690425253024,19.747112123389797",
                         "-32.32714646938548,19.74653276624258"]
        let locationString = locations[Int(arc4random_uniform(UInt32(locations.count)))]
        
        let categories = plannedActivities.components(separatedBy: ",").map({ AfrikaBurnElement.Category(name: $0) })
        return AfrikaBurnElement(id: idInt, name: title, categories: categories, longBlurb: longBlurb, shortBlurb: nil, scheduledActivities: plannedActivitiesDescription, elementType: elementType, locationString: locationString)
    }
}
