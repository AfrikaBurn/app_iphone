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
    
    fileprivate lazy var displayedFields: [Fields] = Fields.create(from: self.element)
    
    static func create(element: AfrikaBurnElement) -> BurnElementDetailViewController {
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BurnElementDetailViewController") as! BurnElementDetailViewController
        detail.element = element
        return detail
    }
    struct ReuseIdentifiers {
        static let cell = "cell"
        static let mapCell = "MapCell"
    }
    var token: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifiers.cell)
        tableView.dataSource = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        token = self.persistentStore.favorites().filter("id == \(element.id)").observe({ (change) in
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(icon: self.element.isFavorite ? .favoriteFilledIn : .favorite, target: self, action: #selector(self.handleFavoriteTapped))
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = element.name
        navigationController?.navigationBar.barTintColor = UIColor.afrikaBurnContentBackgroundColor
        
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.afrikaBurnTintColor]
    }
    
    @objc func handleFavoriteTapped() {
        if element.isFavorite {
            persistentStore.removeFavorite(element)
        } else {
            persistentStore.favoriteElement(element)
        }
    }
}

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

extension BurnElementDetailViewController: UITableViewDataSource {
    
    enum Fields {
        case id, title, categories, longblurb, scheduledActivivies, map
        static let all: [Fields] = [map, title, categories, longblurb, scheduledActivivies]
        
        static func create(from element: AfrikaBurnElement) -> [Fields] {
            let hasText: (_ string: String?) -> Bool = { $0?.isEmpty == false }
            return Fields.all.filter({ (field) -> Bool in
                switch field {
                case .id: return true
                case .categories: return element.categories.count > 0
                case .longblurb: return hasText(element.longBlurb)
                case .scheduledActivivies: return hasText(element.scheduledActivities)
                case .title: return true
                case .map: return element.location != nil
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let dequeueRegularCell: () -> UITableViewCell = { tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.cell, for: indexPath) }
        let text: String?
        switch displayedFields[indexPath.row] {
        case .id:
            cell = dequeueRegularCell()
            text = "\(element.id)"
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
            cell = dequeueRegularCell()
            text = element.name
        case .map:
            text = nil
            let mapCell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.mapCell, for: indexPath) as! MapCell
            cell = mapCell
            let mapView = mapCell.mapView
            mapView.removeAnnotations(mapCell.mapView.annotations)
            if let location = element.location {
                let annotation = BurnAnnotation(coordinate: location, element: element)
                annotation.coordinate = location
                mapView.addAnnotation(annotation)
                mapView.setRegion(MKCoordinateRegionMakeWithDistance(location, 100, 100), animated: false)
            }
            
        }
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
