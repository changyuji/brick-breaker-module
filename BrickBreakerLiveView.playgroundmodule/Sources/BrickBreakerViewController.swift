//
//  BrickBreakerViewController.swift
//
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import SPCCore
import SPCLiveView
import SPCScene
import SPCAudio
import SPCAccessibility
import SPCLearningTrails
import PlaygroundSupport
import UIKit

public class BrickBreakerViewController: LiveViewController {
    
    private var accessibilityManager: AccessibilityManager?
    private var accessibilityButton: AccessibilityButton?

    public init() {        
        super.init(nibName: nil, bundle: nil)
        
        // Display step title in step header instead of step type.
        LearningTrails.isStepTitleInHeader = true
        
        LiveViewController.contentPresentation = .aspectFitMinimum
        
        classesToRegister = [SceneProxy.self, AudioProxy.self, AccessibilityProxy.self]
        let liveViewScene = LiveViewScene(size: Scene.sceneSize)
        
        let accessibilityManager = AccessibilityManager(scene: liveViewScene)
        accessibilityManager.delegate = self
        self.accessibilityManager = accessibilityManager
        
        let accessibilityButton = AccessibilityButton(manager: accessibilityManager)
        accessibilityButton.isEnabled = false
        self.accessibilityButton = accessibilityButton
        
        let learningTrailsButton = LearningTrailsBarButton()
        
        lifeCycleDelegates = [audioController, liveViewScene, learningTrailsButton, accessibilityManager]
        contentView = liveViewScene.skView
        
        // Debugging Physics Bodies
//        liveViewScene.skView.showsPhysics = true
//        liveViewScene.skView.showsFPS = true
        
        addBarButton(accessibilityButton)
        addBarButton(learningTrailsButton)
    }

    required init?(coder: NSCoder) {
        fatalError("BrickBreakerViewController.init?(coder) not implemented.")
    }
}

// Implementing this indirectly via AccessibilityManager due to this limitation:
// "Overriding non-@objc declarations from extensions is not supported" if you attempt
// to conform BrickBreakerViewController to LiveViewLifeCycleProtocol.
extension BrickBreakerViewController: AccessibilityManagerDelegate {
    
    public func liveViewMessageConnectionClosed(_ manager: AccessibilityManager) {
        accessibilityButton?.dismissConfigurationMenu()
        accessibilityButton?.isEnabled = false
    }
    
    public func liveViewMessageConnectionOpened(_ manager: AccessibilityManager) {
        accessibilityButton?.isEnabled = true
    }
}

