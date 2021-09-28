//
//  Sound.swift
//  
//  Copyright © 2016-2019 Apple Inc. All rights reserved.
//

import Foundation

/// The base protocol for sound support.
///
/// - localizationKey: Sound
public typealias Sound = String

/// The base protocol for Music support.
///
/// - localizationKey: Music
public typealias Music = String

public extension String {
    var url : URL? {
        return Bundle.main.url(forResource: self, withExtension: "m4a")
    }
}
