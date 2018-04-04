//
//  AfrikaBurn+Calendar.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2018/04/02.
//  Copyright © 2018 AfrikaBurn. All rights reserved.
//

import Foundation

extension Calendar {
    static var afrikaburnOpenDate: Date {
        var eventOpeningDay = DateComponents()
        eventOpeningDay.day = 23
        eventOpeningDay.month = 4
        eventOpeningDay.year = 2018
        return Calendar(identifier: .gregorian).date(from: eventOpeningDay) ?? Date()
    }
    
    static var daysUntilAfrikaBurn: Int {
        return Calendar(identifier: .gregorian).dateComponents([.day], from: Date(), to: afrikaburnOpenDate).day ?? 0
    }
    
    static var hasAfrikaBurnStarted: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "AssumeBurnHasStarted") {
            return true
        }
        #endif
        
        return Calendar.daysUntilAfrikaBurn <= 0
    }
}
