//
//  AfrikaBurnElement.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import RealmSwift
import CoreLocation


class CustomLocation: Object {

    
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var locationString: String = ""
    dynamic var isHomeCamp: Bool = false
    
    public override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(name: String, coordinate: CLLocationCoordinate2D, isHomeCamp: Bool) {
        
        let latitude = String(format:"%f", coordinate.latitude)
        let longitude = String(format:"%f", coordinate.longitude)
        
        self.init()
        self.id = NSUUID().uuidString
        self.name = name
        self.locationString = "\(latitude),\(longitude)"
        self.isHomeCamp = isHomeCamp        
    }
    
    var coordinates: CLLocationCoordinate2D? {
        
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
}
