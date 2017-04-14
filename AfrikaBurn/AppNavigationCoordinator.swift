//
//  AppNavigationCoordinator.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/04/05.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import UIKit

class AppNavigationCoordinator {
    
    enum Tab: Int {
        case allElements
        case favorites
        case map
    }
    
    fileprivate enum Controller {
        case allElements(BurnElementsViewController)
        case favorites(BurnElementsViewController)
        case map(MapViewController)
    }
    
    let tabs: [Tab] = [.allElements, .favorites, .map]
    
    let tabBarController: UITabBarController
    
    init(tabBarController: UITabBarController) {
        self.tabBarController = tabBarController
        favoritesController.showFavorites()
    }
    
    var favoritesController: BurnElementsViewController {
        let nav = (tabBarController.viewControllers![Tab.favorites.rawValue] as! UINavigationController)
        return nav.viewControllers[0] as! BurnElementsViewController
    }
}

class RootTabBarController: UITabBarController {
}
