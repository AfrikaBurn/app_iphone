//
//  BurnElementDetailViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/07.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit

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

    @IBOutlet weak var tableView: UITableView!
    fileprivate(set) var camp: AfrikaBurnElement!
    
    fileprivate lazy var displayedFields: [Fields] = Fields.create(from: self.camp)
    
    static func create(camp: AfrikaBurnElement) -> BurnElementDetailViewController {
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BurnElementDetailViewController") as! BurnElementDetailViewController
        detail.camp = camp
        return detail
    }
    struct ReuseIdentifiers {
        static let cell = "cell"
        static let mapCell = "MapCell"
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: ReuseIdentifiers.cell)
        tableView.dataSource = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        navigationItem.rightBarButtonItem = UIBarButtonItem(icon: .favorite, target: self, action: #selector(handleFavoriteTapped))
    }
    
    @objc func handleFavoriteTapped() {
        
    }
}

import MapKit
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
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
                case .map: return true
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
            text = "\(camp.id)"
        case .categories:
            cell = dequeueRegularCell()
            text = camp.categories.map({ $0.name }).joined(separator: "\n")
        case .longblurb:
            cell = dequeueRegularCell()
            text = (camp.longBlurb ?? "")
        case .scheduledActivivies:
            cell = dequeueRegularCell()
            text = (camp.scheduledActivities ?? "")
        case .title:
            cell = dequeueRegularCell()
            text = camp.name
        case .map:
            text = nil
            cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.mapCell, for: indexPath) as! MapCell
        }
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
