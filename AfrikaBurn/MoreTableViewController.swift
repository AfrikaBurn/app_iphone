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

    struct URLs {
        static let survivalGuide = Bundle.main.url(forResource: "AB-SurvivalGuide-2018-English", withExtension: "pdf")!
    }
    
    struct IndexPaths {
        static let navigateToTheBurn = IndexPath(row: 0, section: 0)
        static let survivalGuide = IndexPath(row: 1, section: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Style.apply(to: tableView)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPaths.navigateToTheBurn:
            let coordinate = CLLocationCoordinate2DMake(-32.3268322, 19.748085700000047)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
            mapItem.name = "Afrikaburn"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        case IndexPaths.survivalGuide:
            let d = UIDocumentInteractionController(url: URLs.survivalGuide)
            d.name = "Survival Guide"
            d.delegate = self
            d.presentPreview(animated: true)
        default:
            assert(false)
        }
    }

}

extension MoreTableViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}
