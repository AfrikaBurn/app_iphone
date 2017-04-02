//
//  AfrikaBurn+UIKit.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/07.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

extension UITableView {
    func enableSelfSizingCells(withEstimatedHeight estimatedHeight: CGFloat) {
        estimatedRowHeight = estimatedHeight
        rowHeight = UITableViewAutomaticDimension
    }
    
    func scrollToTop(animated: Bool) {
        scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
    }
    
    func handleRealmChanges<T: Object>(_ changes: RealmCollectionChange<Results<T>>, section: Int = 0) {
        switch changes {
        case .error(_):
            break
        case .initial(_):
            reloadData()
        case .update(_, let deletions, let insertions, let modifications):
            handleUpdates(deletions: deletions, insertions: insertions, modifications: modifications)
        }
    }
    
    func handleUpdates(deletions: [Int], insertions: [Int], modifications: [Int]) {
        beginUpdates()
        let intToIndexPath: ([Int]) -> [IndexPath] = { $0.map({IndexPath(row: $0, section: 0)}) }
        insertRows(at: intToIndexPath(insertions), with: .automatic)
        deleteRows(at: intToIndexPath(deletions), with: .automatic)
        reloadRows(at: intToIndexPath(modifications), with: .automatic)
        endUpdates()
    }
}

extension UIColor {
    public static let afrikaBurnTintColor: UIColor = UIColor(red:0.95, green:0.42, blue:0.33, alpha:1.0)
    public static let afrikaBurnBgColor: UIColor = UIColor(red:0.20, green:0.04, blue:0.07, alpha:1.0)
}
