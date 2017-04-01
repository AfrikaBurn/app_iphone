//
//  PersistentStore.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import RealmSwift

class PersistentStore {
    
    let queue = DispatchQueue(label: "PersistentStore.queue")
    
    fileprivate func createRealm() -> Realm {
        return try! Realm()
    }
    
    /*
     Saves the provided elements to Realm.
     `deleteRestNotIncludedInElements` controls whether the elements missing from the provided elements
     should be deleted. This ensures that the data displayed always matches what is stored.
     */
    func storeElements(_ elements: [AfrikaBurnElement], deleteRestNotIncludedInElements: Bool = true) {
        queue.async {
            let realm = self.createRealm()
            try? realm.write {
                if deleteRestNotIncludedInElements {
                    let idsToSave = elements.map({ $0.id })
                    let toDelete = realm.objects(AfrikaBurnElement.self).filter("NOT id in %@", idsToSave)
                    realm.delete(toDelete)
                }
                
                for element in elements {
                    if let f = self.favoritedElement(with: element.id, using: realm) {
                        element.dateFavorited = f.dateFavorited
                        element.isFavorite = f.isFavorite
                    }
                }
                
                realm.add(elements, update: true)
            }
        }
    }
    
    func elements() -> Results<AfrikaBurnElement> {
        let realm = createRealm()
        return realm.objects(AfrikaBurnElement.self)
    }
    
    func favorites() -> Results<AfrikaBurnElement> {
        let realm = createRealm()
        return realm.objects(AfrikaBurnElement.self).filter("isFavorite = true")
    }
    
    fileprivate func favoritedElement(with id: Int, using realm: Realm) -> AfrikaBurnElement? {
        return realm.objects(AfrikaBurnElement.self).first(where: { $0.id == id && $0.isFavorite == true})
    }
    
    func favoriteElement(_ element: AfrikaBurnElement) {
        let realm = self.createRealm()
        try? realm.write {
            element.isFavorite = true
            element.dateFavorited = Date()
        }
    }
    
    func removeFavorite(_ element: AfrikaBurnElement) {
        let realm = self.createRealm()
        try? realm.write {
            element.isFavorite = false
        }
    }
}
