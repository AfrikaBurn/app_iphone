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

extension BurnElementDetailViewController: UITableViewDataSource {
    
    enum Fields {
        case id, title, categories, longblurb, scheduledActivivies
        static let all: [Fields] = [id, title, categories, longblurb, scheduledActivivies]
        
        static func create(from element: AfrikaBurnElement) -> [Fields] {
            let hasText: (_ string: String?) -> Bool = { $0?.isEmpty == false }
            return Fields.all.filter({ (field) -> Bool in
                switch field {
                case .id: return true
                case .categories: return element.categories.count > 0
                case .longblurb: return hasText(element.longBlurb)
                case .scheduledActivivies: return hasText(element.scheduledActivities)
                case .title: return true
                }
            })
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.cell, for: indexPath)
        let text: String?
        switch displayedFields[indexPath.row] {
        case .id:
            text = "id\n" + "\(camp.id)"
        case .categories:
            text = "categories\n" + camp.categories.reduce("", { $0 + "\($1.name), " })
        case .longblurb:
            text = "longblurb\n" + (camp.longBlurb ?? "")
        case .scheduledActivivies:
            text = "scheduled activities\n" + (camp.scheduledActivities ?? "")
        case .title:
            text = "title\n" + camp.name
        }
        cell.textLabel?.text = text
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
