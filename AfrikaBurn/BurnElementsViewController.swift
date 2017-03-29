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

class BurnElementsViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
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
    
    // we store the filtered elements in another property so we can revert back to them after a search filter
    var filteredElements : Results<AfrikaBurnElement>! = nil
    lazy var allElements: Results<AfrikaBurnElement> = self.persistentStore.elements()
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        elements = allElements
        filteredElements = allElements
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the Scope Bar
        // If we want a type filter we could add below... Not sure it's needed
        // searchController.searchBar.scopeButtonTitles = ["All", "Art", "Theme Camps", "MVs", "Performances"]
        tableView.tableHeaderView = searchController.searchBar

    }
    
    @IBAction func handleFilterTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Filter", message: "Select a category", preferredStyle: .actionSheet)
        for type in AfrikaBurnElement.ElementType.filterableList {
            actionSheet.addAction(UIAlertAction(title: type.filterTitle, style: .default, handler: { _ in
                self.elements = self.allElements.filter(type: type)
                // store the filtered elements in another property so we can revert back to them after a search filter
                self.filteredElements = self.elements
                self.navigationItem.leftBarButtonItem?.title = type.filterTitle
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Reset", style: .default, handler: { _ in
            self.elements = self.allElements
            self.filteredElements = self.allElements
            self.navigationItem.leftBarButtonItem?.title = "Filter"
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    private func observeChanges(to elements: Results<AfrikaBurnElement>) {
        self.notificationToken = elements.addNotificationBlock { [weak self] (changes) in
            self?.tableView.handleRealmChanges(changes)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController){
        let searchText = searchController.searchBar.text
        if (searchText == nil || searchText! == "") {
            // search text is empty, need to show full results.
            // revert back to filtered elements rather than all elements so that it keeps previous filter
            self.elements = self.filteredElements
            return
        }
        
        let lowerText = searchText!.lowercased()
        let filter = "name CONTAINS[c] '\(lowerText)' OR shortBlurb CONTAINS[c] '\(lowerText)'"
        
        // we could search self.filteredElements here if we think the search should only filter a subset of the full results.
        // I think searching all results is fine -- JC
        self.elements = self.allElements.filter(filter)
        NSLog("Search text %@ %d", filter, self.elements.count)
        
        self.tableView.reloadData()
        
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

