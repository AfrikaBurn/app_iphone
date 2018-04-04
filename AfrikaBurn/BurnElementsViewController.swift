//
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
    
    struct Configuration {
        static let maxCellCountToHideSearchBar = 10
    }
    
    @IBOutlet weak var tableView: UITableView!
    
    let persistentStore = PersistentStore()
    
    lazy var viewModel: BurnElementsViewModel = BurnElementsViewModel(persistentStore: self.persistentStore)
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.scrollsToTop = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.cellLayoutMarginsFollowReadableWidth = true
        Style.apply(to: tableView)
        tableView.enableSelfSizingCells(withEstimatedHeight: 55)
        
        displaySearchBarIfNeeded()
        
        // Setup the Scope Bar
        // If we want a type filter we could add below... Not sure it's needed
        // searchController.searchBar.scopeButtonTitles = ["All", "Art", "Theme Camps", "MVs", "Performances"]
        viewModel.elementsChangedHandler = { [weak self] changes in
            self?.handleRealmChanges(changes)
        }
        let title: String
        switch viewModel.displayMode {
        case .default:
            title = "All"
        case .favorites:
            title = "Favorites"
        }
        self.title = title
    }
    
    fileprivate func handleRealmChanges(_ changes: BurnElementsViewModel.ElementsChange) {
        guard let tableView = tableView else {
            return
        }
        switch changes {
        case .reload:
            tableView.reloadData()
        case .update(let deletions, let insertions, let modifications):
            tableView.handleUpdates(deletions: deletions, insertions: insertions, modifications: modifications)
        }
    }
    
    func showFavorites() {
        viewModel.displayMode = .favorites
    }
    
    @IBAction func handleFilterTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Filter", message: "Select a category", preferredStyle: .actionSheet)
        actionSheet.view.tintColor = UIColor.afrikaBurnTintColor
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
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let searchText = searchController.searchBar.text, searchText.isEmpty == false else {
            viewModel.searchText = ""
            return
        }
        
        let lowerText = searchText.lowercased()
        viewModel.searchText = lowerText
    }
    
    func displaySearchBarIfNeeded() {
        func showSearch() {
            // Setup the Search Controller
            searchController.searchResultsUpdater = self
            searchController.searchBar.delegate = self
            searchController.searchBar.barTintColor = UIColor.afrikaBurnContentBackgroundColor
            
            definesPresentationContext = true
            searchController.dimsBackgroundDuringPresentation = false
            if #available(iOS 11.0, *) {
                navigationItem.searchController = searchController
                navigationItem.hidesSearchBarWhenScrolling = false
            } else {
                if tableView.tableHeaderView == nil {
                    tableView.tableHeaderView = searchController.searchBar
                }
            }
        }
        
        func hideSearch() {
            if #available(iOS 11.0, *) {
                if navigationItem.searchController != nil {
                    navigationItem.searchController = nil
                }
            } else {
                if tableView.tableHeaderView != nil {
                    tableView.tableHeaderView = nil
                }
            }
        }
        
        if viewModel.searchText.isEmpty {
            if viewModel.numberOfElements > Configuration.maxCellCountToHideSearchBar {
                showSearch()
            } else {
                hideSearch()
            }
        }
    }
}

extension BurnElementsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfCells = viewModel.numberOfElements
        return numberOfCells
    }
    
    func element(at indexPath: IndexPath) -> BurnElementSummaryDisplayable {
        return viewModel.element(at: indexPath.row)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifiers.campSummary, for: indexPath) as! CampSummaryTableViewCell
        let element = self.element(at: indexPath)
        cell.headlineLabel.text = element.elementTitle
        cell.subheadlineLabel.text = element.summaryBlurb
        cell.elementImageView.image = element.iconImage
        return cell
    }
}

extension BurnElementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = self.element(at: indexPath)
        guard let burnElement = self.persistentStore.elements().first(where: { $0.id == element.elementID }) else {
            return
        }
        navigationCoordinator.showBurnElementDetail(for: burnElement)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

class CampSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var headlineLabel: UILabel!
    
    @IBOutlet weak var subheadlineLabel: UILabel!
    @IBOutlet weak var elementImageView: UIImageView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Style.apply(to: self)
    }
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
    var iconImage: UIImage? { get }
    var elementID: Int { get }
}

extension AfrikaBurnElement: BurnElementSummaryDisplayable {
    var elementTitle: String { return name }
    var summaryBlurb: String? { return shortBlurb }
    var iconImage: UIImage? { return elementType.iconImage }
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
    
    var searchText = String() {
        didSet {
            self.elements = applySearchTextFilter(searchText: searchText)
        }
    }
    
    enum ElementsChange {
        case reload
        case update(deletions: [Int], insertions: [Int], modifications: [Int])
    }
    
    var activeFilter: Filter = Filter() {
        didSet {
            let newElements: CurrentElements
            switch elements {
            case .favorites(_):
                newElements = .favorites(applyFilter(activeFilter, to: persistentStore.favorites()))
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
                newElements = .favorites(applyFilter(activeFilter, to: persistentStore.favorites()))
            }
            self.elements = newElements
        }
    }
    
    var elementsChangedHandler: ((ElementsChange) -> Void)?
    
    private enum CurrentElements {
        case normal(Results<AfrikaBurnElement>)
        case favorites(Results<AfrikaBurnElement>)
        
        var results: Results<AfrikaBurnElement> {
            switch self {
            case .favorites(let r): return r
            case .normal(let r): return r
            }
        }
    }
    
    private let persistentStore: PersistentStore
    private let allElements: Results<AfrikaBurnElement>
    private var notificationToken: NotificationToken?
    
    private var elements: CurrentElements {
        didSet {
            observeChanges(to: elements.results)
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
        case .favorites(let favorites):
            return favorites.count
        case .normal(let normal):
            return normal.count
        }
    }
    
    func element(at index: Int) -> BurnElementSummaryDisplayable {
        return elements.results[index]
    }
    
    private func applySearchTextFilter(searchText : String) -> CurrentElements{
        
        let newElements: CurrentElements
        
        // if it's an empty search then just show previous filter
        if (searchText.isEmpty){
            switch displayMode {
            case .default:
                newElements = .normal(applyFilter(activeFilter, to: self.allElements))
            case .favorites:
                newElements = .favorites(applyFilter(activeFilter, to: persistentStore.favorites()))
            }
            return newElements
        }
        
        
        let searchedElements = self.allElements.filter("name CONTAINS[c] '\(searchText)' OR longBlurb CONTAINS[c] '\(searchText)'")
        switch displayMode {
        case .default:
            newElements = .normal(searchedElements)
        case .favorites:
            newElements = .favorites(searchedElements)
        }
        
        return newElements
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
    
    
    private func observeChanges<T: AfrikaBurnElement>(to elements: Results<T>) {
        self.notificationToken = elements.observe { [weak self] (changes) in
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
