//
//  LocationManager.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/04/15.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

class LocationUpdatedToken {
    fileprivate let handler: UserLocationUpdatedHandler
    
    init(handler: @escaping UserLocationUpdatedHandler) {
        self.handler = handler
    }
}

typealias UserLocationUpdatedHandler = (CLLocation) -> Void
class LocationManager: NSObject {
    private let manager = CLLocationManager()
    
    static let sharedInstance = LocationManager()
    
    var usersCurrentLocation: CLLocation? {
        didSet {
            if let location = usersCurrentLocation {
                self.locationUpdatedObservers.allObjects.forEach({ $0.handler(location) })
            }
        }
    }
    
    private var locationUpdatedObservers: NSHashTable<LocationUpdatedToken> = NSHashTable(options: .weakMemory)
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func isAuthorizedToUseLocation() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    func monitorCurrentLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func stopMonitoringLocation() {
        manager.stopUpdatingLocation()
    }
    
    func userDisplayableDistance(from fromLocation: CLLocation, to toLocation: CLLocation) -> String{
        let formatter = MKDistanceFormatter()
        formatter.units = .metric
        return formatter.string(fromDistance: fromLocation.distance(from: toLocation))
    }
    
    func observeUserLocation(_ handler: @escaping UserLocationUpdatedHandler) -> LocationUpdatedToken {
        monitorCurrentLocation()
        let token = LocationUpdatedToken(handler: handler)
        locationUpdatedObservers.add(token)
        if let location = usersCurrentLocation {
            handler(location)
        }
        return token
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        usersCurrentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
