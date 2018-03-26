//
//  MoreTableViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/03/26.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import UIKit
import MapKit

class MoreTableViewController: UITableViewController {

    struct IndexPaths {
        static let navigateToTheBurn = IndexPath(row: 0, section: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPaths.navigateToTheBurn:
            let coordinate = CLLocationCoordinate2DMake(-32.3268322, 19.748085700000047)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = "Afrikaburn"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        default:
            assert(false)
        }
    }

}
