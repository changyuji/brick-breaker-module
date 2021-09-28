//
//  Messagable.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation

public protocol Messagable: Codable {
    static func decode(data: Data, withId id: String)
}
