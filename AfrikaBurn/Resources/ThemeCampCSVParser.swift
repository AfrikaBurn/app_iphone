//
//  ThemeCampCSVParser.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import CHCSVParser



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
    
    enum ParserType {
        case bundledCSV(path: URL)
        case downloadedCSV(String)
    }
    
    fileprivate var currentField: Field = .title
    fileprivate var elements: [AfrikaBurnElement] = []
    fileprivate var shouldIgnoreCurrentLine: Bool = false
    
    fileprivate var currentLineValues: [Field: String] = [:]
    
    let parserType: ParserType
    
    init(parserType: ParserType = .bundledCSV(path: Bundle.main.url(forResource: "theme_camp", withExtension: "csv")!)) {
        self.parserType = parserType
    }
    
    func parse(_ completion: @escaping (_ elements: [AfrikaBurnElement]) -> Void) {
        DispatchQueue.global(qos: .background).async {
            completion(self.parseSync())
        }
    }
    
    func parseSync() -> [AfrikaBurnElement] {
        elements.removeAll()
        currentLineValues.removeAll()
        let parser: CHCSVParser
        switch parserType {
        case .bundledCSV(let path):
            parser = CHCSVParser(contentsOfCSVURL: path)
        case .downloadedCSV(let text):
            parser = CHCSVParser(csvString: text)
        }
        parser.sanitizesFields = true
        parser.trimsWhitespace = true
        
        parser.delegate = self
        parser.parse()
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
        let type = currentLineValues[.type]!
        guard let elementType = AfrikaBurnElement.ElementType(name: type) else {
            return
        }
        let title = currentLineValues[.title]!
        let categories: [AfrikaBurnElement.Category]
        if let categoryNames = currentLineValues[.categories]?.components(separatedBy: ","), categoryNames.count > 0 {
            categories = categoryNames.map({ AfrikaBurnElement.Category(name: $0) })
        } else {
            categories = []
        }
        let longBlurb = currentLineValues[.longblurb]!
        let shortBlurb = currentLineValues[.shortblurb]!
        let activities = currentLineValues[.scheduledActivities]!
        
        let element: AfrikaBurnElement = AfrikaBurnElement(id: id, name: title, categories: categories, longBlurb: longBlurb, shortBlurb: shortBlurb, scheduledActivities: activities, elementType: elementType)
        self.elements.append(element)
    }
}
