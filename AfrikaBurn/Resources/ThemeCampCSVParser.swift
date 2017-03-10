//
//  ThemeCampCSVParser.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import CHCSVParser

struct Camp {
    struct Category {
        let name: String
    }
    let id: Int
    let title: String
    let categories: [Category]
    let longBlurb: String
    let shortBlurb: String
    let scheduledActivities: String
    let type: String
}

class ThemeCampCSVParser : NSObject {
    
    enum Field: Int {
        case id, title, categories, longblurb, scheduledActivities, shortblurb, type
        static let requiredFields: [Field] = [title, categories, longblurb, scheduledActivities, shortblurb, type, id]
    }
    
    fileprivate var currentField: Field = .title
    fileprivate var camps: [Camp] = []
    fileprivate var shouldIgnoreCurrentLine: Bool = false
    
    fileprivate var currentLineValues: [Field: String] = [:]
    
    fileprivate var csvFilePath: URL {
        return Bundle.main.url(forResource: "theme_camp", withExtension: "csv")!
    }
    
    func parse(_ completion: @escaping (_ camps: [Camp]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(self.parseSync())
        }
    }
    
    func parseSync() -> [Camp] {
        camps.removeAll()
        currentLineValues.removeAll()
        let parser = CHCSVParser(contentsOfCSVURL: csvFilePath)
        parser?.sanitizesFields = true
        parser?.trimsWhitespace = true
        
        parser?.delegate = self
        parser?.parse()
        return camps
    }
}

extension ThemeCampCSVParser: CHCSVParserDelegate {
    
    func parser(_ parser: CHCSVParser!, didBeginLine recordNumber: UInt) {
        currentLineValues.removeAll()
        shouldIgnoreCurrentLine = recordNumber < 2
    }
    
    func parser(_ parser: CHCSVParser!, didReadField field: String!, at fieldIndex: Int) {
        guard shouldIgnoreCurrentLine == false else { return }
        let currentField = Field(rawValue: fieldIndex)!
        currentLineValues[currentField] = field
    }
    
    func parser(_ parser: CHCSVParser!, didEndLine recordNumber: UInt) {
        guard Set(currentLineValues.keys).isSuperset(of: Set(Field.requiredFields)),
            let id = Int(currentLineValues[.id]!) else {
            return
        }
        let title = currentLineValues[.title]!
        let categories: [Camp.Category] = []
        let longBlurb = currentLineValues[.longblurb]!
        let shortBlurb = currentLineValues[.shortblurb]!
        let activities = currentLineValues[.scheduledActivities]!
        let type = currentLineValues[.type]!
        let camp = Camp(id: id,title: title, categories: categories, longBlurb: longBlurb, shortBlurb: shortBlurb, scheduledActivities: activities, type: type)
        camps.append(camp)
        
    }
}
