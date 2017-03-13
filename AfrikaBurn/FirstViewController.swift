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
    
    var camps: [Camp] = [] {
        didSet {
            tableView.reloadData()
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        }
    }
    var allCamps: [Camp] = []
    
    lazy var types: Set<String> = {
        let types: Set<String> = Set(self.camps.map { $0.type })
        return types
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        camps = ThemeCampCSVParser().parseSync()
        allCamps = camps
    }
    @IBAction func handleFilterTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Filter", message: "choose a type", preferredStyle: .actionSheet)
        for type in types {
            actionSheet.addAction(UIAlertAction(title: type, style: .default, handler: { _ in
                self.camps = self.allCamps.filter({ $0.type == type })
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Reset", style: .default, handler: { _ in
            self.camps = self.allCamps
        }))
        present(actionSheet, animated: true, completion: nil)
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

