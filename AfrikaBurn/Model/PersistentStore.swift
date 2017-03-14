//
//  PersistentStore.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import RealmSwift

class PersistentStore {
    
    fileprivate func createRealm() -> Realm {
        return try! Realm()
    }
    
    func storeElements(_ elements: [AfrikaBurnElement], deleteRestNotIncludedInElements: Bool = true) {
        DispatchQueue.global(qos: .background).async {
            let realm = self.createRealm()
            /*
             let context = Element.Context.dailyElement
             let idsToSave = elements.map { $0.id }
             db.delete(Element.self, matchingPredicate: NSPredicate(format: "NOT id IN %@", argumentArray: [idsToSave]), context: context)
             */
            try! realm.write {
                if deleteRestNotIncludedInElements {
                    let idsToSave = elements.map({ $0.id })
                    let toDelete = realm.objects(AfrikaBurnElement.self).filter("NOT id in %@", idsToSave)
                    realm.delete(toDelete)
                }
                realm.add(elements, update: true)
            }
        }
    }
    
    func elements() -> Results<AfrikaBurnElement> {
        let realm = createRealm()
        return realm.objects(AfrikaBurnElement.self)
    }
}
