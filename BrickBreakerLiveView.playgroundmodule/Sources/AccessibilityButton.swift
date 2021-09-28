//
//  AccessibilityButton.swift
//
//  Copyright © 2016-2020 Apple Inc. All rights reserved.
//

import UIKit
import SwiftUI
import SPCLiveView

public class AccessibilityButton: BarButton {
    
    let accessibilityManager: AccessibilityManager

    public init(manager: AccessibilityManager) {
        self.accessibilityManager = manager
        super.init(frame: CGRect.zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(self, action: #selector(didTapConfigurationBarButton(_:)), for: .touchUpInside)
        
        updateConfigurationButton()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) has not been implemented")
    }
        
    @objc
    func didTapConfigurationBarButton(_ button: UIButton) {
        if dismissConfigurationMenu() {
            // Just dismissing a previously presented `ConfigurationMenuController`.
            return
        }
        
        let accessibilityControls = AccessibilityControlsViewController()
                
        accessibilityControls.delegate = accessibilityManager
        accessibilityControls.gameSpeed = accessibilityManager.gameSpeed
        accessibilityControls.paddleSize = accessibilityManager.paddleSize
        accessibilityControls.enableCollisionAnnouncements = accessibilityManager.enableCollisionAnnouncements
        accessibilityControls.pauseDuringAnnouncements = accessibilityManager.pauseDuringAnnouncements
        accessibilityControls.isGamePaused = accessibilityManager.isPaused
        
        accessibilityControls.modalPresentationStyle = .popover
        
        accessibilityControls.popoverPresentationController?.permittedArrowDirections = .up
        accessibilityControls.popoverPresentationController?.sourceView = button
        
        accessibilityControls.popoverPresentationController?.sourceRect = bounds
        accessibilityControls.popoverPresentationController?.delegate = self
        presenter?.present(accessibilityControls, animated: true, completion: nil)
    }
    
    /// Dismisses the menu if visible. Returns true if there was a menu to dismiss
    @discardableResult
    func dismissConfigurationMenu() -> Bool {
        if let vc = presenter?.presentedViewController as? AccessibilityControlsViewController {
            vc.dismiss(animated: true, completion: nil)
            return true
        }
        return false
    }
    
    private func updateConfigurationButton() {
        setTitle(nil, for: .normal)
        
        let iconImage = UIImage(named: "gear")?.withRenderingMode(.alwaysTemplate)
        
        accessibilityLabel =
            NSLocalizedString("Game Settings", tableName: "BrickBreakerLiveView", comment: "AX hint for the configuration button.")
        
        setImage(iconImage, for: .normal)
    }
}

extension AccessibilityButton: UIPopoverPresentationControllerDelegate {
    // MARK: UIPopoverPresentationControllerDelegate
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
