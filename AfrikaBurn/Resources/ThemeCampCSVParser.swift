//
//  ThemeCampCSVParser.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/04.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation
import CHCSVParser

class BurnElementsCSVParser : NSObject {
    
    enum Field: Int {
        case id, title, categories, longblurb, scheduledActivities, shortblurb, type, latitude,	longitude, infustructure
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
        guard let currentField = Field(rawValue: fieldIndex) else {
            NSLog("Unrecognized field: %d  %@", fieldIndex, field);
            assert(false, "Found an unrecognized field \(field)")
            return
        }
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
        
        
        
        let locationNotSet : Bool = (currentLineValues[.latitude] == nil || currentLineValues[.latitude]!.isEmpty) ||
                            (currentLineValues[.longitude] ==  nil || currentLineValues[.longitude]!.isEmpty)
        
        // use lat lng from the csv if it's there, otherwise use the seed for now
        var locationString: String
        if (locationNotSet){
            locationString = getSeedLocationString()
        } else {
            let latitude = currentLineValues[.latitude]!
            let longitude = currentLineValues[.longitude]!
            locationString = "\(latitude),\(longitude)"
        }
        
        let element: AfrikaBurnElement = AfrikaBurnElement(id: id, name: title, categories: categories, longBlurb: longBlurb, shortBlurb: shortBlurb, scheduledActivities: activities, elementType: elementType, locationString: locationString) // lat,lng
        self.elements.append(element)
    }
    
    func getSeedLocationString() -> String {
        var seedLocations = [
            "-32.328597649122543,19.749989048242471",
            "-32.328596649122543,19.749898048242471",
            "-32.328195649122543,19.749777048242471",
            "-32.328294649122543,19.749666048242471",
            "-32.328393649122543,19.749555048242471",
            "-32.328492649122543,19.749464048242471",
            "-32.328691649122543,19.749333048242471",
            "-32.328895649122543,19.749272048242471",
            "-32.328994649122543,19.749161048242471",
            "-32.328393649122543,19.749050048242471",
            "-32.328592649122543,19.749050548242471",
            
            // cluster 2
            "-32.327597649122543,19.748989048242471",
            "-32.327596649122543,19.748898048242471",
            "-32.327195649122543,19.748777048242471",
            "-32.327294649122543,19.748666048242471",
            "-32.327393649122543,19.748555048242471",
            "-32.327492649122543,19.748464048242471",
            "-32.327691649122543,19.748333048242471",
            "-32.327895649122543,19.748272048242471",
            "-32.327994649122543,19.748161048242471",
            "-32.327393649122543,19.748050048242471",
            
            // cluster 3
            "-32.326597649122543,19.747989048242471",
            "-32.326596649122543,19.747898048242471",
            "-32.326195649122543,19.747777048242471",
            "-32.326294649122543,19.747666048242471",
            "-32.326393649122543,19.747555048242471",
            "-32.326492649122543,19.747464048242471",
            "-32.326691649122543,19.747333048242471",
            "-32.326895649122543,19.747272048242471",
            "-32.326994649122543,19.747161048242471",
            "-32.326393649122543,19.747050048242471",
            
            // cluster 4
            "-32.325597649122543,19.746989048242471",
            "-32.325596649122543,19.746898048242471",
            "-32.325195649122543,19.746777048242471",
            "-32.325294649122543,19.746666048242471",
            "-32.325393649122543,19.746555048242471",
            "-32.325492649122543,19.746464048242471",
            "-32.325691649122543,19.746333048242471",
            "-32.325895649122543,19.746272048242471",
            "-32.325994649122543,19.746161048242471",
            "-32.325393649122543,19.746050048242471",
            
            // cluster 5
            "-32.329597649122543,19.746989048242471",
            "-32.329596649122543,19.746898048242471",
            "-32.329195649122543,19.746777048242471",
            "-32.329294649122543,19.746666048242471",
            "-32.329393649122543,19.746555048242471",
            "-32.329492649122543,19.746464048242471",
            "-32.329691649122543,19.746333048242471",
            "-32.329895649122543,19.746272048242471",
            "-32.329994649122543,19.746161048242471",
            "-32.329393649122543,19.746050048242471",
            
            // cluster 6
            "-32.330597649122543,19.748989048242471",
            "-32.330596649122543,19.748898048242471",
            "-32.330195649122543,19.748777048242471",
            "-32.330294649122543,19.748666048242471",
            "-32.330393649122543,19.748555048242471",
            "-32.330492649122543,19.748464048242471",
            "-32.330691649122543,19.748333048242471",
            "-32.330895649122543,19.748272048242471",
            "-32.330994649122543,19.748161048242471",
            "-32.330393649122543,19.748050048242471",
            
            // cluster 7
            "-32.331597649122543,19.748989048242471",
            "-32.331596649122543,19.748898048242471",
            "-32.331195649122543,19.748777048242471",
            "-32.331294649122543,19.748666048242471",
            "-32.331393649122543,19.748555048242471",
            "-32.331492649122543,19.748464048242471",
            "-32.331691649122543,19.748333048242471",
            "-32.331895649122543,19.748272048242471",
            "-32.331994649122543,19.748161048242471",
            "-32.331393649122543,19.748050048242471",
            
            // cluster 8
            "-32.332597649122543,19.747989048242471",
            "-32.332596649122543,19.747898048242471",
            "-32.332195649122543,19.747777048242471",
            "-32.332294649122543,19.747666048242471",
            "-32.332393649122543,19.747555048242471",
            "-32.332492649122543,19.747464048242471",
            "-32.332691649122543,19.747333048242471",
            "-32.332895649122543,19.747272048242471",
            "-32.332994649122543,19.747161048242471",
            "-32.332393649122543,19.747050048242471",
            
            // cluster 9
            "-32.331597649122543,19.746989048242471",
            "-32.331596649122543,19.746898048242471",
            "-32.331195649122543,19.746777048242471",
            "-32.331294649122543,19.746666048242471",
            "-32.331393649122543,19.746555048242471",
            "-32.331492649122543,19.746464048242471",
            "-32.331691649122543,19.746333048242471",
            "-32.331895649122543,19.746272048242471",
            "-32.331994649122543,19.746161048242471",
            "-32.331393649122543,19.746050048242471"
        ]
        
        let randomIndex = Int(arc4random_uniform(UInt32(seedLocations.count)))
        
        return seedLocations[randomIndex]
        
    }
}
