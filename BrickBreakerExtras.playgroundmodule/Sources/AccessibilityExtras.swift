//
//  AccessibilityExtras.swift
//
//  Copyright © 2016-2020 Apple Inc. All rights reserved.
//

import UIKit
import SPCScene
import SPCAccessibility

extension Scene {
    
    // Returns the graphics placed on the scene with specified name.
    public func getPlacedGraphics(named name: String) -> [Graphic] {
        return placedGraphics.values.filter({ $0.name == name })
    }
}

extension Graphic {
    
    // Returns the accessibility label for a specified key.
    public static func accessibilityLabelFor(for key: String) -> String {
        switch key {
        case "ball":
            return NSLocalizedString("Ball", comment: "AX Label: Ball")
        case "brick":
            return NSLocalizedString("Brick", comment: "AX Label: Brick")
        case "paddle":
            return NSLocalizedString("Paddle", comment: "AX Label: Paddle")
        case "wall":
            return NSLocalizedString("Wall", comment: "AX Label: Wall")
        case "top-wall":
            return NSLocalizedString("Top wall", comment: "AX Label: Wall at the top")
        case "left-wall":
            return NSLocalizedString("Left-hand wall", comment: "AX Label: Wall on the left")
        case "right-wall":
            return NSLocalizedString("Right-hand wall", comment: "AX Label: Wall on the right")
        case "foul-line":
            return NSLocalizedString("Foul line", comment: "AX Label: Foul line")

        default:
            return ""
        }
    }

    // Adds an accessibility element for the graphic.
    // Uses the specified key or, if omitted, the graphic name, to look up the accessibility label.
    public func addAccessibility(usingKey key: String = "", actions: [AccessibilityAction] = [.noAction]) {
        let lookupKey = key.isEmpty ? self.name : key
        let axLabel = Graphic.accessibilityLabelFor(for: lookupKey)
        guard !axLabel.isEmpty else { return }
        accessibilityHints = AccessibilityHints(makeAccessibilityElement: true, accessibilityLabel: axLabel, actions: actions)
    }
        
}
