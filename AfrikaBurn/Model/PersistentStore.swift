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
    
    func storeElements(_ elements: [AfrikaBurnElement]) {
        DispatchQueue.global(qos: .background).async {
            let realm = self.createRealm()
            try! realm.write {
                realm.add(elements, update: true)
            }
        }
    }
    
    func elements() -> Results<AfrikaBurnElement> {
        let realm = createRealm()
        return realm.objects(AfrikaBurnElement.self)
    }
}
