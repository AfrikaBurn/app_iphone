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
    
    func showBurnElementDetail(for element: AfrikaBurnElement) {
        let detail = BurnElementDetailViewController.create(element: element)
        currentNavigationController?.pushViewController(detail, animated: true)
    }
    
    private var currentNavigationController: UINavigationController? {
        return tabBarController.selectedViewController as? UINavigationController
    }
}

extension UIViewController {
    var navigationCoordinator: AppNavigationCoordinator {
        return (UIApplication.shared.delegate as! AppDelegate).appNavigationCoordinator
    }
}
