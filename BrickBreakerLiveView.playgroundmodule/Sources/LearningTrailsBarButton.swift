//
//  LearningTrailsBarButton.swift
//
//  Copyright © 2020 Apple Computer. All rights reserved.
//

import UIKit
import SPCLiveView
import SPCLearningTrails
import PlaygroundSupport

public class LearningTrailsBarButton: BarButton {
    private let learningTrailAnimationDuration = 0.4
    private let compactLayoutSize = CGSize(width: 507.0, height: 364.0)
    private let kMinBottomAvoidanceMargin = CGFloat(-8)
    private let smallTrailTopConstant = CGFloat(0)
    private let largeTrailTopConstant = CGFloat(64)
    private let smallTrailConstant = CGFloat(0)
    private let largeTrailConstant = CGFloat(44)
    
    private var wasLearningTrailVisibleBeforeRunMyCode = false
    private var trailViewController: LearningTrailViewController?
    private var learningTrailDataSource = DefaultLearningTrailDataSource()
    private var isLearningTrailAnimationInProgress = false
    
    // Indicates whether a Learning Trail should be loaded if present.
    // Should be set before view controller is loaded.
    public var isLearningTrailEnabled = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        let trailButtonImage = UIImage(named: "LearningTrailMaximizeIcon")?.withRenderingMode(.alwaysTemplate)
        let trailButtonSelectedImage = UIImage(named: "LearningTrailMinimize")?.withRenderingMode(.alwaysTemplate)
        
        setImage(trailButtonImage, for: .normal)
        setImage(trailButtonSelectedImage, for: .selected)
        addTarget(self, action: #selector(onTrailButton), for: .touchUpInside)
        alpha = 0.0
        
        updateLearningTrailAX()
        
        // Load the learning trail if there is one.
        guard isLearningTrailEnabled else { return }
        learningTrailDataSource.trail.load(completion: { success in
            DispatchQueue.main.async {
                guard success else { return }
                self.alpha = 1.0
                self.onLearningTrailLoaded(success)
            }
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateButtonBarVisibility(trailVisible: Bool) {
        if var presenter = presenter {
            let horizontalLayout = presenter.liveViewSafeAreaGuide.layoutFrame.size.width > presenter.liveViewSafeAreaGuide.layoutFrame.size.height
            let isHorizontalCompactLayout = horizontalLayout && (presenter.liveViewSafeAreaGuide.layoutFrame.width <= compactLayoutSize.width)
            let isVerticalCompactLayout = !horizontalLayout && (presenter.liveViewSafeAreaGuide.layoutFrame.height <= compactLayoutSize.height)
            
                presenter.barButtonsHidden = (isHorizontalCompactLayout || isVerticalCompactLayout) && isLearningTrailEnabled && trailVisible // Always visible if no learning trail.
            }
    }
    
    @objc
    func onTrailButton(_ button: UIButton) {
        if let vc = presenter?.presentedViewController, vc.modalPresentationStyle == .popover {
            vc.dismiss(animated: true, completion: nil)
        }

        showLearningTrail()
    }
    
    func updateLearningTrailAX() {
        accessibilityIdentifier = "\(String(describing: type(of: self))).learningTrailButton"
        accessibilityLabel = NSLocalizedString("Show Learning Trail", comment: "AX label for learning trail button when it’s hidden.")
    }
    
    // MARK: Learning Trail Overlay
    
        private var learningTrailButtonShrunkenScale: CGFloat {
            return DefaultLearningStepStyle.headerButtonSize.width / frame.size.width
        }
    
        var isLearningTrailVisible: Bool {
            return isSelected
        }
    
        func onLearningTrailLoaded(_ success: Bool) {
            // Display the Learning Trail.
            alpha = 1.0
            
            showLearningTrail()
            
            // Display a message if there was a problem parsing the Learning Trail XML document.
            if !success {
                var message = NSLocalizedString("⚠️ Error loading Learning Trail:", comment: "Error Message: Learning Trail loading")
                
                message += "\n\n"
                message += learningTrailDataSource.trail.errorMessage
                trailViewController?.showMessage(message)
            }
        }
    
        func loadTrailViewController() {
            guard trailViewController == nil else { return }
    
            let trailViewController = LearningTrailViewController()
            trailViewController.learningTrailDataSource = learningTrailDataSource
            trailViewController.delegate = self
            trailViewController.view.translatesAutoresizingMaskIntoConstraints = false
            trailViewController.view.isHidden = true
            
            if let presenter = presenter {
                presenter.addChild(trailViewController)
                
                presenter.view?.addSubview(trailViewController.view!)
                
                let topButtonAvoidanceConstraint = trailViewController.view.topAnchor.constraint(equalTo: presenter.barButtonSafeAreaGuide.topAnchor)
                let bottomKeyboardAvoidanceConstraint = trailViewController.view.bottomAnchor.constraint(equalTo: presenter.barButtonSafeAreaGuide.bottomAnchor, constant: kMinBottomAvoidanceMargin)
                let rightButtonAvoidanceConstraint = trailViewController.view.rightAnchor.constraint(equalTo: presenter.barButtonSafeAreaGuide.rightAnchor)
                let lowPriorityLeftTrailConstraint = trailViewController.view.leftAnchor.constraint(equalTo: presenter.barButtonSafeAreaGuide.leftAnchor)
                let centerXTrailConstraint = trailViewController.view.centerXAnchor.constraint(equalTo: presenter.liveViewSafeAreaGuide.centerXAnchor)
                
                lowPriorityLeftTrailConstraint.priority = .defaultLow
                
                NSLayoutConstraint.activate([
                    topButtonAvoidanceConstraint,
                    lowPriorityLeftTrailConstraint,
                    bottomKeyboardAvoidanceConstraint,
                    rightButtonAvoidanceConstraint,
                    centerXTrailConstraint
                ])
            }
            
            self.trailViewController = trailViewController
            
            presenter?.barButtonLayoutDidChange = {
                if !self.isLearningTrailAnimationInProgress {
                    self.updateButtonBarVisibility(trailVisible: self.isLearningTrailVisible)
                }
            }
        }
    
        func showTrailViewController() {
            guard !isLearningTrailAnimationInProgress else { return }
            guard let trailViewController = self.trailViewController else { return }
    
            isLearningTrailAnimationInProgress = true
            
            if let view = presenter?.view {
                // Show the learning trail.
                let duration = learningTrailAnimationDuration
                let startPoint = superview!.convert(center, to: view) 
                trailViewController.show(from: startPoint, duration: duration, delay: 0.0)
                
                // Animate the learning trail button in parallel so that it lands just where the trail close button will be.
                let startPosition = superview!.convert(center, to: view)
                let endPosition = trailViewController.closeButtonPosition
                let dx = endPosition.x - startPosition.x
                let dy = endPosition.y - startPosition.y
                
                self.updateButtonBarVisibility(trailVisible: true)
                UIView.animate(withDuration: duration, delay: 0.0,
                               options: [ .curveEaseOut, .beginFromCurrentState ],
                               animations: {
                                let transform = CGAffineTransform(translationX: dx, y: dy)
                                self.transform = transform
                                self.backgroundScale = self.learningTrailButtonShrunkenScale
                                self.setSelected(true, delay: 0, duration: duration * 0.4)
                }, completion: { _ in
                    self.alpha = 0.0
                    self.transform = CGAffineTransform.identity
                    self.isLearningTrailAnimationInProgress = false
                    self.isSelected = true
                    
                    // Announce new state of learning trail.
                    let message = NSLocalizedString("Learning Trail shown", comment: "Describes state of learning trail when it’s shown.")
                    UIAccessibility.post(notification: .announcement, argument: message)
                })
            }
        }
    
        func hideTrailViewController() {
            guard !isLearningTrailAnimationInProgress else { return }
            guard let trailViewController = self.trailViewController else { return }
    
            isLearningTrailAnimationInProgress = true
            
            if let view = presenter?.view {
            // Position the learning trail button over the trail close button.
                let trailButtonPosition = superview!.convert(center, to: view)
                let closeButtonPosition = trailViewController.closeButtonPosition
                let dx = closeButtonPosition.x - trailButtonPosition.x
                let dy = closeButtonPosition.y - trailButtonPosition.y
                let transform = CGAffineTransform(translationX: dx, y: dy)
                
                self.transform = transform
                backgroundScale = learningTrailButtonShrunkenScale
                alpha = 1.0
        
                // Hide the learning trail.
                let duration = learningTrailAnimationDuration
                let endPoint = superview!.convert(center, to: view)
                
                trailViewController.hide(to: endPoint, duration: duration, delay: 0.0)
        
                // Animate the learning trail button in parallel back to its original position.
                UIView.animate(withDuration: duration, delay: 0.0,
                               options: [ .curveEaseOut, .beginFromCurrentState ],
                               animations: {
                                self.transform = CGAffineTransform.identity
                                self.backgroundScale = 1.0
                                self.setSelected(false, delay: duration * 0.125, duration: duration * 0.4)
                                self.updateButtonBarVisibility(trailVisible: false)
                }, completion: { _ in
                    self.isLearningTrailAnimationInProgress = false
                    self.isSelected = false
                    
                    // Announce new state of learning trail.
                    let message = NSLocalizedString("Learning Trail hidden", comment: "Describes state of learning trail when it’s hidden.")
                    UIAccessibility.post(notification: .announcement, argument: message)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        UIAccessibility.post(notification: .layoutChanged, argument: self)
                    }
                })
            }
        }
    
    func showLearningTrail() {
        guard isLearningTrailEnabled, !isLearningTrailVisible else { return }
        
        var waitTime = 0.0
        
        if trailViewController == nil {
            loadTrailViewController()
            waitTime = 0.25 // First time: wait for trail view controller constraints to take effect visually.
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + waitTime) {
            self.showTrailViewController()
            self.updateLearningTrailAX()
        }
    }

    func hideLearningTrail() {
        guard isLearningTrailEnabled, isLearningTrailVisible else { return }

        hideTrailViewController()
        updateLearningTrailAX()
    }

    func dismissLearningTrailPopovers() {
        // If there's one or more popovers that are presented from a trail (or its steps), dismiss them.
        trailViewController?.dismiss(animated: false, completion: nil)
    }
}

extension LearningTrailsBarButton: LiveViewLifeCycleProtocol {
    public func liveViewMessageConnectionOpened() {
        wasLearningTrailVisibleBeforeRunMyCode = isLearningTrailVisible

        hideLearningTrail()
        dismissLearningTrailPopovers()
    }
    
    public func liveViewMessageConnectionClosed() {
        // Show the learning trail again if it was visible before.
        if wasLearningTrailVisibleBeforeRunMyCode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.showLearningTrail()
            }
        }
    }
}

extension LearningTrailsBarButton: LearningTrailViewControllerDelegate {
    public func trailViewControllerDidRequestClose(_ trailViewController: LearningTrailViewController) {
        hideLearningTrail()
    }
}

