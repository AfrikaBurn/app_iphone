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
        case "performance", "performance registration", "performances":
            self = .performance
        case "camp", "theme camp form 3 - wtf guide", "theme camps":
            self = .camp
        case "artwork", "artwork registration", "artworks":
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
    
    @objc dynamic var id: Int = -1
    @objc dynamic var name: String = ""
    @objc dynamic var categoriesString: String = ""
    @objc dynamic var longBlurb: String?
    @objc dynamic var shortBlurb: String?
    @objc dynamic var scheduledActivities: String?
    @objc dynamic var elementTypeString: String = ""
    @objc dynamic var locationString: String?
    
    // Favoriting //
    @objc dynamic var dateFavorited: Date = Date()
    @objc dynamic var isFavorite: Bool = false
    
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
