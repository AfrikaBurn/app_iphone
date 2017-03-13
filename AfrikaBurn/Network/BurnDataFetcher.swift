//
//  BurnDataFetcher.swift
//  AfrikaBurn
//
//  Created by Daniel Galasko on 2017/03/13.
//  Copyright © 2017 AfrikaBurn. All rights reserved.
//

import Foundation

typealias BurnDataResponseType = String

class BurnDataFetcher: NSObject {
    enum Result {
        case success(BurnDataResponseType)
        case failed
    }
    
    typealias Completion = (_ result: Result) -> Void
    
    struct Configuration {
        static let endpoint = URL(string: "https://new.afrikaburn.com/api/general")!
    }
    
    enum State {
        case idle
        case fetching
        case fetched(BurnDataResponseType)
        case fetchFailed
    }
    
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
    
    fileprivate func handleResponseReceived(_ data: Data?, error: Error?, completion: @escaping Completion) {
        serialQueue.async {
            if let data = data {
                if let burnDataString = APIResponseSerializer.convertResponse(withData: data) {
                    self.state = .fetched(burnDataString)
                    completion(.success(burnDataString))
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

struct APIResponseSerializer {
    static func convertResponse(withData data: Data) -> BurnDataResponseType? {
        guard let burnDataNSString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return nil
        }
        return burnDataNSString as String
    }
}