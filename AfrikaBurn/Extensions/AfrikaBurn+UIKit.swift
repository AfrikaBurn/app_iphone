//
//  AfrikaBurn+UIKit.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/07.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    func enableSelfSizingCells(withEstimatedHeight estimatedHeight: CGFloat) {
        estimatedRowHeight = estimatedHeight
        rowHeight = UITableViewAutomaticDimension
    }
}
