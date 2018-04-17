//
//  BurnElementDetailViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/07.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit
import MapKit
import RealmSwift

enum BarButtonIcon {
    case favorite
    case favoriteFilledIn
    var image: UIImage {
        switch self {
        case .favorite: return #imageLiteral(resourceName: "favorite-icon")
        case .favoriteFilledIn: return #imageLiteral(resourceName: "favorite-icon-selected")
        }
    }
}

extension UIBarButtonItem {
    convenience init(icon: BarButtonIcon, target: AnyObject?, action: Selector) {
        self.init(image: icon.image, style: .plain, target: target, action: action)
    }
}

class BurnElementDetailViewController: UIViewController {
    
    let persistentStore: PersistentStore = PersistentStore()
    @IBOutlet weak var tableView: UITableView!
    fileprivate(set) var element: AfrikaBurnElement!
    fileprivate var locationObservationToken: Any?
    fileprivate lazy var displayedFields: [Fields] = Fields.create(from: self.element)
    private var locationManager: LocationManager { return LocationManager.sharedInstance }
    
    static func create(element: AfrikaBurnElement) -> BurnElementDetailViewController {
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BurnElementDetailViewController") as! BurnElementDetailViewController
        detail.element = element
        return detail
    }
    
    struct ReuseIdentifiers {
        static let cell = "cell"
        static let headlineCell = "headlineCell"
        static let mapCell = "MapCell"
    }
    
    var token: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        tableView.allowsSelection = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifiers.cell)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifiers.headlineCell)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        Style.apply(to: tableView)
        token = self.persistentStore.favorites().filter("id == \(element.id)").observe({ (change) in
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: self.element.isFavorite ? .favoriteFilledIn : .favorite, target: self, action: #selector(self.handleFavoriteTapped))
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = element.name
    }
    
    @objc func handleFavoriteTapped() {
        if element.isFavorite {
            persistentStore.removeFavorite(element)
        } else {
            persistentStore.favoriteElement(element)
        }
    }
}

extension BurnElementDetailViewController: UITableViewDataSource {
    
    enum Fields {
        case title, categories, longblurb, scheduledActivivies, map
        static let all: [Fields] = [map, title, categories, longblurb, scheduledActivivies]
        
        static func create(from element: AfrikaBurnElement) -> [Fields] {
            let hasText: (_ string: String?) -> Bool = { $0?.isEmpty == false }
            return Fields.all.filter({ (field) -> Bool in
                switch field {
                case .categories: return element.categories.count > 0
                case .longblurb: return hasText(element.longBlurb)
                case .scheduledActivivies: return hasText(element.scheduledActivities)
                case .title: return true
                case .map:
                    return false//element.location != nil
                }
            })
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayedFields.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch displayedFields[section] {
        case .categories:
            return "Times"
        case .longblurb:
            return nil
        case .scheduledActivivies:
            return "Scheduled Activities"
        case .title:
            return nil
        case .map:
            return "Location"
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let dequeueRegularCell: () -> UITableViewCell = { tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.cell, for: indexPath) }
        let dequeueHeadlineCell: () -> UITableViewCell = { tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.headlineCell, for: indexPath) }
        let text: String?
        switch displayedFields[indexPath.section] {
        case .categories:
            cell = dequeueRegularCell()
            text = element.categories.map({ $0.name }).joined(separator: "\n")
        case .longblurb:
            cell = dequeueRegularCell()
            text = (element.longBlurb ?? "")
        case .scheduledActivivies:
            cell = dequeueRegularCell()
            text = (element.scheduledActivities ?? "")
        case .title:
            cell = dequeueHeadlineCell()
            if #available(iOS 11.0, *) {
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.largeTitle)
            } else {
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
            }
            text = element.name
        case .map:
            cell = dequeueRegularCell()
            text = DisplayableDistance.distance(from: locationManager.usersCurrentLocation, to: element.location, using: locationManager)
            if let location = element.location {
                locationObservationToken = locationManager.observeUserLocation { [weak self] (userLocation) in
                    guard let strongSelf = self else { return }
                    print(userLocation)
                    if let cell = strongSelf.tableView.cellForRow(at: indexPath) {
                        let distance = DisplayableDistance.distance(from: userLocation, to: location, using: strongSelf.locationManager)
                        cell.textLabel?.text = distance
                    }
                }
            }
        }
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        return cell
    }
    
    struct DisplayableDistance {
        static func distance(from: CLLocation?, to: CLLocation?, using manager: LocationManager) -> String {
            guard manager.isAuthorizedToUseLocation() else {
                return "⚠️ Please grant access to your location in Settings so we can give you a distance to this point"
            }
            if let from = from, let to = to {
                let distance = manager.userDisplayableDistance(from: from, to: to)
                return "🏃‍♀️ \(distance) away from you"
            } else {
                return "⏰ getting current location"
            }
        }
    }
}

extension BurnElementDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.tableView(tableView, titleForHeaderInSection: section) == nil ? CGFloat.leastNonzeroMagnitude : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.tableView(tableView, titleForHeaderInSection: section) == nil ? CGFloat.leastNonzeroMagnitude : 44
    }
}

//MARK: - Cells -

class MapCell: UITableViewCell {
    
    let mapView: BurnMapView = {
        let m = BurnMapView(frame: .zero)
        m.isUserInteractionEnabled = false
        m.translatesAutoresizingMaskIntoConstraints = false
        return m
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    func setup() {
        contentView.addSubview(mapView)
        mapView.bounds = bounds
        mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        mapView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        mapView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}

extension MapCell : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard let burnAnnotation = annotation as? BurnAnnotation else {
            return nil
        }
        
        let annotationView: MKAnnotationView
        if let reusedAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") {
            annotationView = reusedAnnotationView
            annotationView.annotation = annotation
        } else {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        }
        
        annotationView.image = burnAnnotation.image
        
        return annotationView
    }
}
