//
//  Style.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/03/26.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import Foundation
import UIKit

struct Style {
    static let primaryTintColor = UIColor.create(fromHEX: "F6AE20")
    static let softerTintColor = UIColor.create(fromHEX: "F5DC87")
    
    static let blackColor = UIColor.create(fromHEX: "120D0A")
    static let whiteColor = UIColor.create(fromHEX: "F9F8F3")
    static let redColor = UIColor.create(fromHEX: "E53D2F")
    
    static func configureAppStyle(_ app: UIApplication) {
        UINavigationBar.appearance().tintColor = UIColor.afrikaBurnTintColor
        UINavigationBar.appearance().titleTextAttributes =  [NSAttributedString.Key.foregroundColor: Style.blackColor]
        UINavigationBar.appearance().barTintColor = UIColor.afrikaBurnContentBackgroundColor
        
        UITabBar.appearance().barTintColor = UIColor.afrikaBurnContentBackgroundColor
        UITabBar.appearance().backgroundColor = UIColor.afrikaBurnContentBackgroundColor
        UITabBar.appearance().tintColor = UIColor.afrikaBurnTintColor
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.afrikaBurnTintColor], for: .selected)
        UISearchBar.appearance().tintColor = UIColor.afrikaBurnTintColor
        
        app.keyWindow?.tintColor = UIColor.afrikaBurnTintColor
        
        UIApplication.shared.statusBarStyle = .default
    }
    
    static func apply(to tableView: UITableView) {
        tableView.backgroundView = nil
        tableView.backgroundColor = Style.whiteColor
    }
    
    static func apply(to cell: UITableViewCell) {
        let v = UIView()
        v.backgroundColor = Style.softerTintColor
        cell.selectedBackgroundView = v
    }
}

extension UIColor {
    
    
    public static let afrikaBurnTintColor: UIColor = Style.primaryTintColor
    public static let afrikaBurnContentBackgroundColor: UIColor = Style.whiteColor
    
    class func create(fromHEX hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
