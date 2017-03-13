//
//  AfrikaBurnElement.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import RealmSwift

extension AfrikaBurnElement.ElementType {
    
    init?(name: String) {
        switch name.lowercased() {
        case "mutant vehicles":
            self = .mutantVehicle
        case "performance registration":
            self = .performance
        case "theme camp form 3 - wtf guide":
            self = .camp
        case "performance registration":
            self = .performance
        default:
            return nil
        }
    }
}

extension Results where T: AfrikaBurnElement {
    func filter(type: T.ElementType) -> Results<T> {
        return filter("elementTypeString == %@", type.rawValue)
    }
}

class AfrikaBurnElement: Object {
    enum ElementType: String {
        case mutantVehicle
        case camp
        case artwork
        case performance
    }
    
    struct Category {
        let name: String
    }
    
    dynamic var id: Int = -1
    dynamic var name: String = ""
    dynamic var categoriesString: String = ""
    dynamic var longBlurb: String?
    dynamic var shortBlurb: String?
    dynamic var scheduledActivities: String?
    dynamic var elementTypeString: String = ""
    
    var categories: [Category] {
        let names  = categoriesString.components(separatedBy: ",")
        return names.map({ Category(name: $0) })
    }
    
    var elementType: AfrikaBurnElement.ElementType {
        return AfrikaBurnElement.ElementType(name: self.elementTypeString) ?? .camp
    }
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(id: Int, name: String, categories: [Category], longBlurb: String?, shortBlurb: String?, scheduledActivities: String?, elementType: AfrikaBurnElement.ElementType) {
        self.init()
        self.id = id
        self.name = name
        self.categoriesString = categories.map({ $0.name }).joined()
        self.longBlurb = longBlurb
        self.shortBlurb = shortBlurb
        self.scheduledActivities = scheduledActivities
        self.elementTypeString = elementType.rawValue
    }
}
