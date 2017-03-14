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
    
    /*
     Saves the provided elements to Realm.
     `deleteRestNotIncludedInElements` controls whether the elements missing from the provided elements
     should be deleted. This ensures that the data displayed always matches what is stored.
     */
    func storeElements(_ elements: [AfrikaBurnElement], deleteRestNotIncludedInElements: Bool = true) {
        DispatchQueue.global(qos: .background).async {
            let realm = self.createRealm()
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
