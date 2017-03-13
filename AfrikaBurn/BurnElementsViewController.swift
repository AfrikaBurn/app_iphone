//
//  BurnElementsViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit
import RealmSwift

class CampSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var headlineLabel: UILabel!
    
    @IBOutlet weak var subheadlineLabel: UILabel!
    
}

extension AfrikaBurnElement.ElementType {
    var filterTitle: String {
        switch self {
        case .artwork: return "Artworks"
        case .camp: return "Theme Camps"
        case .mutantVehicle: return "Mutant Vehicles"
        case .performance: return "Performances"
        }
    }
    
    static let filterableList: [AfrikaBurnElement.ElementType] = [camp, artwork, mutantVehicle, performance]
}

class BurnElementsViewController: UIViewController {
    
    struct ReuseIdentifiers {
        static let campSummary = "CampSummaryTableViewCell"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let persistentStore = PersistentStore()
    private var notificationToken: NotificationToken?
    
    var elements: Results<AfrikaBurnElement>! {
        didSet {
            tableView.scrollToTop(animated: false)
            observeChanges(to: elements)
        }
    }
    
    lazy var allElements: Results<AfrikaBurnElement> = self.persistentStore.elements()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        elements = allElements
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
    }
    
    @IBAction func handleFilterTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Filter", message: "Select a category", preferredStyle: .actionSheet)
        for type in AfrikaBurnElement.ElementType.filterableList {
            actionSheet.addAction(UIAlertAction(title: type.filterTitle, style: .default, handler: { _ in
                self.elements = self.allElements.filter(type: type)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Reset", style: .default, handler: { _ in
            self.elements = self.allElements
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func observeChanges(to elements: Results<AfrikaBurnElement>) {
        self.notificationToken = elements.addNotificationBlock { [weak self] (changes) in
            self?.tableView.handleRealmChanges(changes)
        }
    }
}

extension BurnElementsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return elements.count
    }
    
    func element(at indexPath: IndexPath) -> AfrikaBurnElement {
        return elements[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.campSummary, for: indexPath) as! CampSummaryTableViewCell
        let element = self.element(at: indexPath)
        cell.headlineLabel.text = element.name
        cell.subheadlineLabel.text = element.shortBlurb
        return cell
    }
}

extension BurnElementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = self.element(at: indexPath)
        let detail = BurnElementDetailViewController.create(camp: element)
        navigationController?.pushViewController(detail, animated: true)
    }
}

