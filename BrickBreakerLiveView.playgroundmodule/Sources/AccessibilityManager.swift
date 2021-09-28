//
//  AccessibilityManager.swift
//
//  Copyright © 2016-2020 Apple Inc. All rights reserved.
//

import UIKit
import SpriteKit
import SPCLiveView
import SPCScene

private extension InteractionCategory {
    static let axBall = InteractionCategory(rawValue: 1 << 0)
    static let axPaddle = InteractionCategory(rawValue: 1 << 1)
    static let axBrick = InteractionCategory(rawValue: 1 << 2)
    static let axWall = InteractionCategory(rawValue: 1 << 3)
    static let axFoulLine = InteractionCategory(rawValue: 1 << 4)
    static let axKnob = InteractionCategory(rawValue: 1 << 5)
    static let axInactive = InteractionCategory(rawValue: 1 << 6)
}

public protocol AccessibilityManagerDelegate  {
    func liveViewMessageConnectionOpened(_ manager: AccessibilityManager)
    func liveViewMessageConnectionClosed(_ manager: AccessibilityManager)
}

public class AccessibilityManager {
    
    private let scene: LiveViewScene
        
    public var delegate: AccessibilityManagerDelegate?
    
    public private(set) var gameSpeed: Float = 1.0 {
        didSet {
            update()
        }
    }
    
    public private(set) var paddleSize: Float = 1.0 {
        didSet {
            update()
        }
    }
    
    public var isPaused: Bool {
        return scene.physicsWorld.speed == 0
    }
    
    public private(set) var enableCollisionAnnouncements = true
    public private(set) var pauseDuringAnnouncements = false // Disabled due to rdar://59350425
    public private(set) var isPausedDuringAnnouncements = false
    
    public init(scene: LiveViewScene) {
        self.scene = scene
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(forName: LiveViewScene.didCreateGraphic, object: scene, queue: .main)
        { [unowned self] _ in
            self.update()
        }
        
        notificationCenter.addObserver(forName: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil, queue: .main) { [unowned self] notification in
            self.updateForVoiceOverState()
        }
        
        notificationCenter.addObserver(forName: LiveViewScene.collisionOccurred, object: scene, queue: .main) { [unowned self] notification in
            
            guard UIAccessibility.isVoiceOverRunning else { return }

            guard
                let firstGraphic = notification.userInfo?[LiveViewScene.firstGraphicKey] as? LiveViewGraphic,
                let secondGraphic = notification.userInfo?[LiveViewScene.secondGraphicKey] as? LiveViewGraphic
                else { return }

            if (firstGraphic.interactionCategory == .axBall) {
                self.handleBallCollision(ball: firstGraphic, other: secondGraphic)
            }
            if (secondGraphic.interactionCategory == .axBall) {
                self.handleBallCollision(ball: secondGraphic, other: firstGraphic)
            }
            
        }
        
        notificationCenter.addObserver(forName: UIAccessibility.announcementDidFinishNotification, object: nil, queue: .main) { [unowned self] notification in
            if self.isPausedDuringAnnouncements {
                self.isPausedDuringAnnouncements = false
                self.run()
            }
        }
        
        updateForVoiceOverState()
    }
    
    // Public Methods
    
    public func pause(withAnnouncement: Bool = false) {
        let wasPaused = isPaused
        scene.physicsWorld.speed = 0
        if UIAccessibility.isVoiceOverRunning {
            if withAnnouncement && !wasPaused {
                let preface = NSLocalizedString("Game paused.", tableName: "BrickBreakerLiveView", comment: "AX announcement that game is paused")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.announceCurrentGameState(preface: preface)
                }
            }
        }
    }
    
    public func run(withAnnouncement: Bool = false) {
        let wasRunning = !isPaused
        if UIAccessibility.isVoiceOverRunning {
            if withAnnouncement && !wasRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.scheduleVoiceOverAnnouncement(message: NSLocalizedString("Game resumed.", tableName: "BrickBreakerLiveView", comment: "AX announcement that game is resumed"))
                }
            }
        }
        update()
    }
    
    // MARK: - Private Methods
    
    private func update() {
        
        // Change the size for all sprites named "paddle"
        for paddle in scene.graphicsInfo(forName: "paddle") {
            paddle.backingNode.xScale = CGFloat(paddleSize)
        }
        
        scene.physicsWorld.speed = CGFloat(gameSpeed)
    }
    
    private func updateForVoiceOverState() {

    }
    
    private func scheduleVoiceOverAnnouncement(message: String) {
        guard !message.isEmpty else { return }
        if pauseDuringAnnouncements && !isPausedDuringAnnouncements {
            pause()
            isPausedDuringAnnouncements = true
        }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    private func handleBallCollision(ball: LiveViewGraphic, other: LiveViewGraphic) {
        guard enableCollisionAnnouncements else { return }
        if other.interactionCategory == .axBrick {
            // Slight delay to allow collided brick to be removed before announcement.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.speakBallHitBrickMessage()
            }
        } else if other.interactionCategory == .axWall {
            if other.position.x == 0 && other.position.y < 0 {
                // Must be the foul line.
                // Slight delay to allow collided ball to be removed before announcement.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.speakBallHitFoulLineMessage()
                }
            }
        }
    }
    
    private func announceCurrentGameState(preface: String) {
        var description = preface
        description += " "
        description += speakableBricksDescription
        description += ". "
        description += speakablePaddleDescription
        description += " "
        description += speakableBallsDescription
        scheduleVoiceOverAnnouncement(message: description)
    }
    
    private var activeBricks: [LiveViewGraphic] {
        return scene.graphicsInfo(forName: "brick").filter({ $0.backingNode.parent != nil })
    }
    
    private var speakableBricksCount: String {
        let brickCount = activeBricks.count
        var description = ""
        if brickCount == 0 {
            description += NSLocalizedString("No bricks", tableName: "BrickBreakerLiveView", comment: "AX description when there are no bricks")
        } else if brickCount == 1 {
            description += NSLocalizedString("One brick", tableName: "BrickBreakerLiveView", comment: "AX description when there is one brick")
        } else {
            description += String(format:
            NSLocalizedString("%d bricks", tableName: "BrickBreakerLiveView", comment: "AX description of the remaining brick count"),
               brickCount)
        }
        return description
    }
    
    private var speakableBricksDescription: String {
        return String(format: NSLocalizedString("%@ left", tableName: "BrickBreakerLiveView", comment: "AX announcement of number of items left"), speakableBricksCount)
    }
    
    private var speakablePaddleDescription: String {
        guard let paddle = scene.graphicsInfo(forName: "paddle").first else { return "" }
        var description = ""
        //let percent = Int(abs(paddle.position.x) / 500.0) * 100
        if paddle.position.x == 0 {
            description += NSLocalizedString("Paddle in the center.", tableName: "BrickBreakerLiveView", comment: "AX description when paddle is in the center")
        } else if paddle.position.x < 0 {
            description += NSLocalizedString("Paddle left of center.", tableName: "BrickBreakerLiveView", comment: "AX description when paddle is on the left")
        } else if paddle.position.x > 0 {
            description += NSLocalizedString("Paddle right of center.", tableName: "BrickBreakerLiveView", comment: "AX description when paddle is on the right")
        }
        return description
    }
    
    private var speakableBallsCount: String {
        let balls = scene.graphicsInfo(nameStartsWith: "ball")
        if balls.count == 0 {
            return NSLocalizedString("No balls", tableName: "BrickBreakerLiveView", comment: "AX ball count when there are no balls left")
        } else if balls.count == 1 {
            return NSLocalizedString("One ball", tableName: "BrickBreakerLiveView", comment: "AX ball count when there is one ball")
        } else {
            return String(format: NSLocalizedString("%d balls", tableName: "BrickBreakerLiveView", comment: "AX ball count"), balls.count)
        }
    }
    
    private var speakableBallsDescription: String {
        return String(format: NSLocalizedString("%@ left", tableName: "BrickBreakerLiveView", comment: "AX announcement of number of items left"), speakableBallsCount)
    }
        
    private func speakBallHitBrickMessage() {
        guard enableCollisionAnnouncements else { return }
        scheduleVoiceOverAnnouncement(message: speakableBricksDescription)
    }
    
    private func speakBallHitFoulLineMessage() {
        var message = NSLocalizedString("Ball hit foul-line.", tableName: "BrickBreakerLiveView", comment: "AX announcement when ball hits foul line")
            message += speakableBallsDescription
        scheduleVoiceOverAnnouncement(message: message)
    }
}

extension AccessibilityManager: LiveViewLifeCycleProtocol {
    public func liveViewMessageConnectionOpened() {
        run(withAnnouncement: true)
        delegate?.liveViewMessageConnectionOpened(self)
    }
    
    public func liveViewMessageConnectionClosed() {
        pause(withAnnouncement: true)
        delegate?.liveViewMessageConnectionClosed(self)
    }
}

extension AccessibilityManager: AccessibilityControlsDelegate {
    public func accessibilityControls(_ controller: AccessibilityControlsViewController, paddleSizeChanged size: Float) {
        paddleSize = size
    }
    
    public func accessibilityControls(_ controller: AccessibilityControlsViewController, gameSpeedChanged speed: Float) {
        gameSpeed = speed
    }
    
    public func accessibilityControls(_ controller: AccessibilityControlsViewController, enableCollisionAnnouncements: Bool) {
        self.enableCollisionAnnouncements = enableCollisionAnnouncements
    }
    
    public func accessibilityControls(_ controller: AccessibilityControlsViewController, pauseDuringAnnouncements: Bool) {
        self.pauseDuringAnnouncements = pauseDuringAnnouncements
    }
    
    public func accessibilityControls(_ controller: AccessibilityControlsViewController, pauseGame: Bool) {
        if pauseGame {
            pause(withAnnouncement: true)
        } else {
            run(withAnnouncement: true)
        }
    }
}
