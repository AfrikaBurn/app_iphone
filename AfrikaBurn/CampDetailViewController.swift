//
//  CampDetailViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/07.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit

class CampDetailViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    fileprivate(set) var camp: Camp!
    
    static func create(camp: Camp) -> CampDetailViewController {
        let detail = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CampDetailViewController") as! CampDetailViewController
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
    }
}

extension CampDetailViewController: UITableViewDataSource {
    enum Fields {
        case id, title, categories, longblurb, scheduledActivivies, type
        static let all: [Fields] = [id, title, categories, type, longblurb, scheduledActivivies]
    }
    
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return Fields.all.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.cell, for: indexPath)
            let text: String
            switch Fields.all[indexPath.row] {
            case .id:
                text = "\(camp.id)"
            case .categories:
                text = camp.categories.reduce("", { $0 + "\($1.name), " })
            case .longblurb:
                text = camp.longBlurb
            case .scheduledActivivies:
                text = camp.scheduledActivities
            case .title:
                text = camp.title
            case .type:
                text = camp.type
            }
            cell.textLabel?.text = text
            cell.textLabel?.numberOfLines = 0
            return cell
        }
}
