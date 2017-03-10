//
//  FirstViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit

class CampSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var headlineLabel: UILabel!
    
    @IBOutlet weak var subheadlineLabel: UILabel!
    
}

class FirstViewController: UIViewController {
    
    struct ReuseIdentifiers {
        static let campSummary = "CampSummaryTableViewCell"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    var camps: [Camp] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        camps = ThemeCampCSVParser().parseSync()
    }
}

extension FirstViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return camps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.campSummary, for: indexPath) as! CampSummaryTableViewCell
        let camp = camps[indexPath.row]
        cell.headlineLabel.text = camp.title
        cell.subheadlineLabel.text = camp.shortBlurb
        return cell
    }
}

extension FirstViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let camp = camps[indexPath.row]
        let detail = CampDetailViewController.create(camp: camp)
        navigationController?.pushViewController(detail, animated: true)
    }
}

