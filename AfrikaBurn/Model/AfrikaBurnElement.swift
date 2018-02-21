//
//  AfrikaBurnElement.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import RealmSwift
import CoreLocation

extension AfrikaBurnElement.ElementType {
    
    init?(name: String) {
        switch name.lowercased() {
        case "mutant vehicles", "mutantvehicle":
            self = .mutantVehicle
        case "performance", "performance registration":
            self = .performance
        case "camp", "theme camp form 3 - wtf guide":
            self = .camp
        case "artwork", "artwork registration":
            self = .artwork
        default:
            print(false, "received an unknown element type \(name)")
            return nil
        }
    }
    
    
    var iconImage : UIImage {
        switch self{
            case .mutantVehicle:
                return #imageLiteral(resourceName: "mutant-vehicle")
        case .performance:
                return #imageLiteral(resourceName: "performance")
        case .camp:
                return #imageLiteral(resourceName: "tent")
        case .artwork:
                return #imageLiteral(resourceName: "brush")
        }
    }
    
    var mapImage : UIImage {
        switch self{
        case .mutantVehicle:
            return #imageLiteral(resourceName: "map-mutant")
        case .performance:
            return #imageLiteral(resourceName: "map-performance")
        case .camp:
            return #imageLiteral(resourceName: "map-camp")
        case .artwork:
            return #imageLiteral(resourceName: "map-artwork")
        }
    }
    
}



extension Results where Element: AfrikaBurnElement {
    func filter(type: Element.ElementType) -> Results<Element> {
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
        
        init(name: String) {
            self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    dynamic var id: Int = -1
    dynamic var name: String = ""
    dynamic var categoriesString: String = ""
    dynamic var longBlurb: String?
    dynamic var shortBlurb: String?
    dynamic var scheduledActivities: String?
    dynamic var elementTypeString: String = ""
    dynamic var locationString: String?
    
    // Favoriting //
    dynamic var dateFavorited: Date = Date()
    dynamic var isFavorite: Bool = false
    
    var location: CLLocationCoordinate2D? {
        guard let locationString = locationString else {
            return nil
        }
        let components = locationString.components(separatedBy: ",")
        guard components.count == 2,
        let latitudeString = components.first,
        let latitude = Double(latitudeString),
        let longitudeString = components.last,
        let longitude = Double(longitudeString) else {
                return nil
        }
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var categories: [Category] {
        guard categoriesString.isEmpty == false else {
            return []
        }
        let names  = categoriesString.components(separatedBy: ",")
        return names.map({ Category(name: $0) })
    }
    
    var elementType: AfrikaBurnElement.ElementType {
        return AfrikaBurnElement.ElementType(name: self.elementTypeString) ?? .camp
    }
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    func normalizeName(name : String) -> String {
        var _name = name;
        _name = name.replacingOccurrences(of: "Theme Camp Form 3 - WTF Guide", with: "Theme Camp")
        _name = name.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        return _name
    }
    
    convenience init(id: Int, name: String, categories: [Category], longBlurb: String?, shortBlurb: String?, scheduledActivities: String?, elementType: AfrikaBurnElement.ElementType, locationString: String) {
        self.init()
        self.id = id
        self.name = normalizeName(name: name)
        self.categoriesString = categories.map({ $0.name }).joined(separator: ",")
        self.longBlurb = longBlurb
        self.shortBlurb = shortBlurb
        self.scheduledActivities = scheduledActivities
        self.elementTypeString = elementType.rawValue
        self.locationString = locationString
    }
}
