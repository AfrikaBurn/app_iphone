//
//  ThemeCampCSVParser.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import CHCSVParser

struct AfrikaBurnElement {
    enum ElementType {
        case mutantVehicle
        case camp
        case artwork
        case performance
    }

    struct Category {
        let name: String
    }
    let id: Int
    let name: String
    let categories: [Category]
    let longBlurb: String?
    let shortBlurb: String?
    let scheduledActivities: String?
    let elementType: ElementType
}

struct MutantVehicle {
    let id: Int
    let name: String
    let longBlurb: String
    let shortBlurb: String
}

struct Artwork {
    let id: Int
    let name: String
}

struct Camp {
    struct Category {
        let name: String
    }
    let id: Int
    let name: String
    let categories: [Category]
    let longBlurb: String
    let shortBlurb: String
    let scheduledActivities: String
}

struct Performance {
    let id: Int
    let name: String
}

class BurnElementsCSVParser : NSObject {
    
    enum Field: Int {
        case id, title, categories, longblurb, scheduledActivities, shortblurb, type
        static let requiredFields: [Field] = [title, categories, longblurb, scheduledActivities, shortblurb, type, id]
    }
    
    fileprivate var currentField: Field = .title
    fileprivate var elements: [AfrikaBurnElement] = []
    fileprivate var shouldIgnoreCurrentLine: Bool = false
    
    fileprivate var currentLineValues: [Field: String] = [:]
    
    fileprivate var csvFilePath: URL {
        return Bundle.main.url(forResource: "theme_camp", withExtension: "csv")!
    }
    
    func parse(_ completion: @escaping (_ elements: [AfrikaBurnElement]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(self.parseSync())
        }
    }
    
    func parseSync() -> [AfrikaBurnElement] {
        elements.removeAll()
        currentLineValues.removeAll()
        let parser = CHCSVParser(contentsOfCSVURL: csvFilePath)
        parser?.sanitizesFields = true
        parser?.trimsWhitespace = true
        
        parser?.delegate = self
        parser?.parse()
        return elements
    }
}

extension BurnElementsCSVParser: CHCSVParserDelegate {
    
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
        let categories: [AfrikaBurnElement.Category] = []
        let longBlurb = currentLineValues[.longblurb]!
        let shortBlurb = currentLineValues[.shortblurb]!
        let activities = currentLineValues[.scheduledActivities]!
        let type = currentLineValues[.type]!
        
        let element: AfrikaBurnElement?
        func createElement(withType type: AfrikaBurnElement.ElementType) -> AfrikaBurnElement {
            return AfrikaBurnElement(id: id, name: title, categories: categories, longBlurb: longBlurb, shortBlurb: shortBlurb, scheduledActivities: activities, elementType: type)
        }
        switch type.lowercased() {
        case "mutant vehicles":
            element = createElement(withType: .mutantVehicle)
        case "performance registration":
            element = createElement(withType: .performance)
        case "theme camp form 3 - wtf guide":
            element = createElement(withType: .camp)
        case "performance registration":
            element = createElement(withType: .performance)
        default:
            element = nil
        }
        if let element = element {
            self.elements.append(element)
        }
    }
}
