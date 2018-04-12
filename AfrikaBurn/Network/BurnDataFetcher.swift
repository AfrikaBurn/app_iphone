//
//  BurnDataFetcher.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation

typealias BurnDataResponseType = [BurnJSONElement]

class BurnDataFetcher {
    
    struct Configuration {
        static let endpoint = URL(string: "https://tribe.afrikaburn.com/api/json")!
    }
    
    enum Result {
        case success(BurnDataResponseType)
        case failed
    }
    
    typealias Completion = (_ result: Result) -> Void
    
    enum State {
        case idle
        case fetching
        case fetched(BurnDataResponseType)
        case fetchFailed
    }
    
    let cache = BurnDataCache()
    private(set) var state = State.idle
    private let serialQueue = DispatchQueue(label: "burndatafetcher.serialqueue")
    
    func fetchData(_ completion: @escaping Completion) {
        serialQueue.async {
            if case .fetching = self.state {
                return
            }
            self.state = .fetching
            URLSession.shared.dataTask(with: Configuration.endpoint) { [weak self] (data, response, error) in
                self?.handleResponseReceived(data, error: error, completion: completion)
                }.resume()
        }
    }
    
    func cachedElements() -> [BurnJSONElement] {
        return cache.retrieveCache()
    }
    
    private func handleResponseReceived(_ data: Data?, error: Error?, completion: @escaping Completion) {
        serialQueue.async {
            if let data = data {
                if let burnElements = APIResponseSerializer.convertResponse(withData: data) {
                    self.cache.cacheElements(burnElements)
                    self.state = .fetched(burnElements)
                    completion(.success(burnElements))
                } else {
                    self.handleFetchFailed(completion: completion)
                }
            } else {
                self.handleFetchFailed(completion: completion)
            }
        }
    }
    
    private func handleFetchFailed(completion: @escaping Completion) {
        self.state = .fetchFailed
        completion(.failed)
    }
}

struct BurnDataCache {
    
    struct CachePath {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cacheFileName = "afrikaburn_burn_data.cache"
        var cacheFilePath: URL{
            return cachesDir.appendingPathComponent(cacheFileName)
        }
    }
    
    func retrieveCache() -> [BurnJSONElement] {
        let path = CachePath().cacheFilePath
        do {
            if let data = FileManager.default.contents(atPath: path.path) {
                return try JSONDecoder().decode([BurnJSONElement].self, from: data)
            }
        }
        catch {
            
        }
        return []
    }
    
    func cacheElements(_ elements: [BurnJSONElement]) {
        do {
            let data = try JSONEncoder().encode(elements)
            let path = CachePath()
            
            try? FileManager.default.createDirectory(at: path.cachesDir, withIntermediateDirectories: true, attributes: nil)
            try? FileManager.default.removeItem(at: path.cacheFilePath)
            
            FileManager.default.createFile(atPath: path.cacheFilePath.path, contents: data, attributes: nil)
            
        } catch {
            
        }
    }
}

struct BurnJSONElement: Codable {
    let id: String
    let type: String
    let title: String
    let longBlurb: String
    let imageURL: String
    let plannedActivities: String
    let plannedActivitiesDescription: String
    let latitude: String?
    let longitude: String?
    
    private enum CodingKeys: String, CodingKey {
        case id = "nid"
        case type = "type"
        case title = "title"
        case longBlurb = "field_prj_wtf_long"
        case imageURL = "field_prj_wtf_image"
        case plannedActivities = "field_prj_wtf_planned"
        case plannedActivitiesDescription = "field_prj_wtf_scheduled"
        case latitude = "field_prj_adm_latitude"
        case longitude = "field_prj_adm_longitude"
    }
}

struct APIResponseSerializer {
    static func convertResponse(withData data: Data) -> BurnDataResponseType? {
        let decoder = JSONDecoder()
        
        do {
            let elements = try decoder.decode([BurnJSONElement].self, from: data)
            return elements
        } catch {
            print(error)
            return nil
        }
    }
}
