//
//  FavoritedElement.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/29.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import RealmSwift

class FavoritedElement: AfrikaBurnElement {
    dynamic var dateAdded: Date = Date()
    convenience init(element: AfrikaBurnElement, dateAdded: Date = Date()) {
        self.init()
        self.id = element.id
        self.name = element.name
        self.categoriesString = element.categoriesString
        self.longBlurb = element.longBlurb
        self.shortBlurb = element.shortBlurb
        self.scheduledActivities = element.scheduledActivities
        self.elementTypeString = element.elementTypeString
        self.locationString = element.locationString
        self.dateAdded = dateAdded
    }
}
