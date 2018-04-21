//
//  LaunchArguments.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/04/21.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import Foundation

struct LaunchArguments {
    static var preventAppStoreReviewPrompts: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "PreventAppStoreReviewPrompts")
        #else
        return false
        #endif
    }
}
