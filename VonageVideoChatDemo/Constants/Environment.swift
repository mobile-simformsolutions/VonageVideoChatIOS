//
//  Environment.swift
//  OpenTokVideoDemo
//
//  Created by Abhi Makadiya on 21/08/20.
//  Copyright © 2020 Abhi Makadiya. All rights reserved.
//

import Foundation

/// AppConstant
public struct AppConstant {
    static let environment = Environment()
    static let openTokApiKey = environment.configuration(PlistKey.openTokApiKey) as? String ?? ""
    static let openTokSessionId = environment.configuration(PlistKey.openTokSessionId) as? String ?? ""
    static let openTokToken = environment.configuration(PlistKey.openTokToken) as? String ?? ""
}

/// PlistKey
public enum PlistKey {
    case openTokApiKey
    case openTokSessionId
    case openTokToken
    
    func value() -> String {
        switch self {
        case .openTokApiKey:
            return "OpenTokApiKey"
        case .openTokSessionId:
            return "OpenTokSessionId"
        case .openTokToken:
            return "OpenTokToken"
        }
    }
    
}

/// Environment
public struct Environment {
    
    /// fetch data from info.plist
    fileprivate var infoDict: [String: Any] {
        get {
            if let dict = Bundle.main.infoDictionary {
                return dict
            } else {
                fatalError("Plist file not found")
            }
        }
    }
    
    /// Provide value from info.plist file
    ///
    /// - Parameter key: Needed key
    /// - Returns: Get value in define datatype(Any you type cast later)
    func configuration(_ key: PlistKey) -> Any {
        switch key {
        case .openTokApiKey:
            return infoDict[PlistKey.openTokApiKey.value()] as? String ?? ""
        case .openTokSessionId:
            return infoDict[PlistKey.openTokSessionId.value()] as? String ?? ""
        case .openTokToken:
            return infoDict[PlistKey.openTokToken.value()] as? String ?? ""
        }
    }
    
}
