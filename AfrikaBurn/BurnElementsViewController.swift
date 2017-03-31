////
//  BurnElementsViewController.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import UIKit
import RealmSwift


class BurnElementsViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate {
    
    struct ReuseIdentifiers {
        static let campSummary = "CampSummaryTableViewCell"
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let persistentStore = PersistentStore()
    
    lazy var viewModel: BurnElementsViewModel = BurnElementsViewModel(persistentStore: self.persistentStore)
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
	// filteredElements = allElements
 
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        searchController.dimsBackgroundDuringPresentation = false
        
        // Setup the Scope Bar
        // If we want a type filter we could add below... Not sure it's needed
        // searchController.searchBar.scopeButtonTitles = ["All", "Art", "Theme Camps", "MVs", "Performances"]
        tableView.tableHeaderView = searchController.searchBar

        viewModel.elementsChangedHandler = { [weak self] changes in
            switch changes {
            case .reload:
                self?.tableView.reloadData()
            case .update(let deletions, let insertions, let modifications):
                self?.tableView.handleUpdates(deletions: deletions, insertions: insertions, modifications: modifications)
            }
        }
    }
    
    @IBAction func handleFavoritesSegmentedControlChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewModel.displayMode = .default
        default:
            viewModel.displayMode = .favorites
        }
    }
    
    
    @IBAction func handleFilterTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Filter", message: "Select a category", preferredStyle: .actionSheet)
        for type in AfrikaBurnElement.ElementType.filterableList {
            actionSheet.addAction(UIAlertAction(title: type.filterTitle, style: .default, handler: { _ in
                self.viewModel.activeFilter.elementType = type
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Reset", style: .default, handler: { _ in
            self.viewModel.activeFilter = BurnElementsViewModel.Filter()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func scrollToTop() {
        tableView.scrollToTop(animated: false)
    }
    
    func updateSearchResults(for searchController: UISearchController){
        
        guard let searchText = searchController.searchBar.text, searchText.isEmpty == false else {
            // search text is empty, need to show full results.
            // revert back to filtered elements rather than all elements so that it keeps previous filter
            NSLog("Revert filter")
//            elements = filteredElements
            return
        }
        
        let lowerText = searchText.lowercased()
        
        viewModel.searchText = lowerText
//        let filter = "name CONTAINS[c] '\(lowerText)' OR shortBlurb CONTAINS[c] '\(lowerText)'"
//        
//        // we could search self.filteredElements here if we think the search should only filter a subset of the full results.
//        // I think searching all results is fine -- JC
////        elements = allElements.filter(filter)
//        NSLog("Perform filter \(filter)")
//        
//        tableView.reloadData()
        
    }
    
}

extension BurnElementsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfElements
    }
    
    func element(at indexPath: IndexPath) -> BurnElementSummaryDisplayable {
        return viewModel.element(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.campSummary, for: indexPath) as! CampSummaryTableViewCell
        let element = self.element(at: indexPath)
        cell.headlineLabel.text = element.elementTitle
        cell.subheadlineLabel.text = element.summaryBlurb
        return cell
    }
}

extension BurnElementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = self.element(at: indexPath)
        guard let burnElement = self.persistentStore.elements().first(where: { $0.id == element.elementID }) else {
            return
        }
        let detail = BurnElementDetailViewController.create(element: burnElement)
        navigationController?.pushViewController(detail, animated: true)
    }
}

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

protocol BurnElementSummaryDisplayable {
    var elementTitle: String { get }
    var summaryBlurb: String? { get }
    var elementID: Int { get }
}

extension AfrikaBurnElement: BurnElementSummaryDisplayable {
    var elementTitle: String { return name }
    var summaryBlurb: String? { return shortBlurb }
    var elementID: Int { return id }
}

class BurnElementsViewModel {
    
    enum DisplayMode {
        case `default`
        case favorites
    }
    
    struct Filter {
        var elementType: AfrikaBurnElement.ElementType?
        init(elementType: AfrikaBurnElement.ElementType? = nil) {
            self.elementType = elementType
        }
    }
    
    struct searchText {
        
    }
    
    enum ElementsChange {
        case reload
        case update(deletions: [Int], insertions: [Int], modifications: [Int])
    }
    
    var activeFilter: Filter = Filter() {
        didSet {
            let newElements: CurrentElements
            switch elements {
            case .favorited(_):
                newElements = .favorited(applyFilter(activeFilter, to: persistentStore.favorites()))
            case .normal(_):
                newElements = .normal(applyFilter(activeFilter, to: self.allElements))
            }
            self.elements = newElements
        }
    }
    
    var displayMode = DisplayMode.default {
        didSet {
            let newElements: CurrentElements
            switch displayMode {
            case .default:
                newElements = .normal(applyFilter(activeFilter, to: self.allElements))
            case .favorites:
                newElements = .favorited(applyFilter(activeFilter, to: persistentStore.favorites()))
            }
            self.elements = newElements
        }
    }
    
    var searchText = String() {
        didSet {
            let newElements: CurrentElements
            switch displayMode {
            case .default:
                newElements = .normal(applyFilter(activeFilter, to: self.allElements))
            case .favorites:
                newElements = .favorited(applyFilter(activeFilter, to: persistentStore.favorites()))
            }
            self.elements = newElements
        }
    }
    
    
    
    var elementsChangedHandler: ((ElementsChange) -> Void)?
    
    private enum CurrentElements {
        case normal(Results<AfrikaBurnElement>)
        case favorited(Results<FavoritedElement>)
    }
    
    private let persistentStore: PersistentStore
    private let allElements: Results<AfrikaBurnElement>
    private var notificationToken: NotificationToken?
    
    private var elements: CurrentElements {
        didSet {
            switch elements {
            case .normal(let elements):
                observeChanges(to: elements)
            case .favorited(let elements):
                observeChanges(to: elements)
            }
        }
    }
    
    init(persistentStore: PersistentStore) {
        let allElements = persistentStore.elements()
        self.persistentStore = persistentStore
        self.elements = .normal(allElements)
        self.allElements = allElements
        
        self.observeChanges(to: allElements)
    }
    
    var numberOfElements: Int {
        switch elements {
        case .favorited(let favorites):
            return favorites.count
        case .normal(let normal):
            return normal.count
        }
    }
    
    func element(at index: Int) -> BurnElementSummaryDisplayable {
        switch elements {
        case .favorited(let favorites):
            return favorites[index]
        case .normal(let normal):
            return normal[index]
        }
    }
    
    
    
    private func applyFilter<T: AfrikaBurnElement>(_ filter: Filter, to elements: Results<T>) -> Results<T> {
        let result: Results<T>
        if let elementType = activeFilter.elementType {
            result = elements.filter(type: elementType)
        } else {
            result = elements
        }
        return result
    }
    
    private func applySearchFilter<T: AfrikaBurnElement>(filterText: String, to elements: Results<T>) -> Results<T> {
        let result: Results<T>
        result = elements.filter("name CONTAINS[c] '\(filterText)' OR shortBlurb CONTAINS[c] '\(filterText)'")
        return result
    }
    
    private func observeChanges<T: AfrikaBurnElement>(to elements: Results<T>) {
        self.notificationToken = elements.addNotificationBlock { [weak self] (changes) in
            switch changes {
            case .error(_):
                break
            case .initial(_):
                self?.elementsChangedHandler?(.reload)
            case .update(_, let deletions, let insertions, let modifications):
                self?.elementsChangedHandler?(.update(deletions: deletions, insertions: insertions, modifications: modifications))
            }
        }
    }
    
}
