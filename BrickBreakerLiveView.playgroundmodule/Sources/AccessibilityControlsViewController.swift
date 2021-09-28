//
//  AccessibilityControlsViewController.swift
//
//  Copyright © 2016-2020 Apple Inc. All rights reserved.
//

import UIKit

public protocol AccessibilityControlsDelegate  {
    func accessibilityControls(_ controller: AccessibilityControlsViewController, paddleSizeChanged size: Float)
    func accessibilityControls(_ controller: AccessibilityControlsViewController, gameSpeedChanged speed: Float)
    func accessibilityControls(_ controller: AccessibilityControlsViewController, enableCollisionAnnouncements: Bool)
    func accessibilityControls(_ controller: AccessibilityControlsViewController, pauseDuringAnnouncements: Bool)
    func accessibilityControls(_ controller: AccessibilityControlsViewController, pauseGame: Bool)
}

public class AccessibilityControlsViewController: UIViewController {
    
    private var stack: UIStackView?
    
    private var paddleSizeSlider: UISlider?
    private var speedSlider: UISlider?
    private var enableCollisionAnnouncementsSwitch: UISwitch?
    private var pauseDuringAnnouncementsSwitch: UISwitch?
    private var pauseButton: UIButton?
    private var resetButton: UIButton?
    
    public var delegate: AccessibilityControlsDelegate?
    
    public var gameSpeed: Float = 1.0 {
        didSet {
            updateControls()
        }
    }
    
    public var paddleSize: Float = 1.0 {
        didSet {
            updateControls()
        }
    }
    
    public var enableCollisionAnnouncements = true {
        didSet {
            updateControls()
        }
    }
    
    public var pauseDuringAnnouncements = false {
        didSet {
            updateControls()
        }
    }
    
    public var isGamePaused = false {
        didSet {
            updateControls()
        }
    }
    
    override public func loadView() {
        let rootView = UIView()
        view = rootView

        stack = setupStack()
        
        paddleSizeSlider =
            setUpSlider(prompt: NSLocalizedString("Paddle Size", comment: "AX menu label for paddle size control"),
                        target: self,
                        action: #selector(setPaddleSize))
        
        speedSlider =
            setUpSlider(prompt: NSLocalizedString("Game Speed", comment: "AX menu label for game speed control"),
                        target: self,
                        action: #selector(setSpeed))
        
        var image: UIImage?
        var selectedImage: UIImage?
        if #available(iOS 13.0, *) {
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .bold)
            image = UIImage(systemName: "pause.circle", withConfiguration: symbolConfiguration)
            selectedImage = UIImage(systemName: "play.circle", withConfiguration: symbolConfiguration)
        }
        pauseButton =
            setupButton(type: .custom, prompt: NSLocalizedString("Pause/Resume Game", comment: "AX menu label for pause/resume game button"),
                        title: NSLocalizedString("Pause Game", comment: "AX label for pause game button"),
                        selectedTitle: NSLocalizedString("Resume Game", comment: "AX label for resume game button"),
                        image: image,
                        selectedImage: selectedImage,
                        target: self,
                        action: #selector(togglePauseGame))
        
        resetButton =
            setupButton(type: .system, title: NSLocalizedString("Reset", comment: "AX label for reset button"),
                    target: self,
                    action: #selector(resetValues))
        
        updatePauseButtonAX()
        
        resetButton?.accessibilityLabel = NSLocalizedString("Reset settings", comment: "AX label reset button.")
        
        // Only show the paddle size control if VoiceOver is running.
        if let paddleSizeRow = stack?.arrangedSubviews.first {
            paddleSizeRow.isHidden = !UIAccessibility.isVoiceOverRunning
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        updateControls()
    }
    
    override public var preferredContentSize: CGSize {
        get {
            return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        }
        set { super.preferredContentSize = newValue }
    }
    
    // MARK: - Layout Methods
    
    func setupStack() -> UIStackView {
        let stack = UIStackView(frame: CGRect.zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 10.0

        view.addSubview(stack)
        
        view.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)

        let margin = view.layoutMarginsGuide

        stack.leadingAnchor.constraint(equalTo: margin.leadingAnchor).isActive = true
        stack.trailingAnchor.constraint(equalTo: margin.trailingAnchor).isActive = true
        stack.topAnchor.constraint(equalTo: margin.topAnchor).isActive = true
        stack.bottomAnchor.constraint(equalTo: margin.bottomAnchor).isActive = true
        
        return stack
    }
    
    func setupToggle(prompt: String, target: Any, action: Selector) -> UISwitch {
        
        let row = UIStackView(frame: CGRect.zero)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = 8.0

        stack?.addArrangedSubview(row)
        
        let theSwitch = UISwitch(frame: CGRect.zero)
        theSwitch.translatesAutoresizingMaskIntoConstraints = false
        theSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        theSwitch.setContentCompressionResistancePriority(.required, for: .vertical)
        
        theSwitch.addTarget(target, action: action, for: .valueChanged)
        
        row.addArrangedSubview(theSwitch)
        
        let text = UILabel(frame: CGRect.zero)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.setContentCompressionResistancePriority(.required, for: .horizontal)
        text.setContentHuggingPriority(.required, for: .vertical)
        text.text = prompt
        row.addArrangedSubview(text)
        
        return theSwitch
    }
    
    func setUpSlider(prompt: String, target: Any, action: Selector) -> UISlider {
        
        let row = UIStackView(frame: CGRect.zero)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .vertical
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = 0.0
        
        stack?.addArrangedSubview(row)
        
        let text = UILabel(frame: CGRect.zero)
        text.translatesAutoresizingMaskIntoConstraints = false
        text.setContentCompressionResistancePriority(.required, for: .horizontal)
        text.setContentHuggingPriority(.defaultLow, for: .horizontal)
        text.setContentHuggingPriority(.required, for: .vertical)
        text.text = prompt
        text.textAlignment = .center
        row.addArrangedSubview(text)
        
        let slider = UISlider(frame: CGRect.zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        slider.setContentCompressionResistancePriority(.required, for: .vertical)
        slider.addTarget(target, action: action, for: .valueChanged)
        slider.isContinuous = true
        slider.minimumValue = 0.1
        slider.maximumValue = 1.9
        row.addArrangedSubview(slider)
    
        return slider
    }
    
    func setupButton(type buttonType: UIButton.ButtonType, prompt: String? = nil, title: String?, selectedTitle: String? = nil, image: UIImage? = nil, selectedImage: UIImage? = nil, target: Any, action: Selector) -> UIButton {
        
        let row = UIStackView(frame: CGRect.zero)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .vertical
        row.alignment = .fill
        row.distribution = .fill
        row.spacing = 8.0

        stack?.addArrangedSubview(row)
        
        if let prompt = prompt {
            let text = UILabel(frame: CGRect.zero)
            text.translatesAutoresizingMaskIntoConstraints = false
            text.setContentCompressionResistancePriority(.required, for: .horizontal)
            text.setContentHuggingPriority(.required, for: .vertical)
            text.text = prompt
            text.textAlignment = .center
            row.addArrangedSubview(text)
        }
        
        let theButton = UIButton(type: buttonType)
        theButton.translatesAutoresizingMaskIntoConstraints = false
        theButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        theButton.setContentCompressionResistancePriority(.required, for: .vertical)
        theButton.addTarget(target, action: action, for: .touchUpInside)
        theButton.setTitleColor(view.tintColor, for: .normal)
        
        row.addArrangedSubview(theButton)
        if let image = image {
            theButton.setImage(image, for: .normal)
        } else {
            theButton.setTitle(title, for: .normal)
        }
        if let selectedImage = selectedImage {
            theButton.setImage(selectedImage, for: .selected)
        } else {
            theButton.setTitle(selectedTitle, for: .selected)
        }
        
        return theButton
    }
    
    func updatePauseButtonAX() {
        guard let pauseButton = pauseButton else { return }
        if pauseButton.isSelected  {
            pauseButton.accessibilityLabel = NSLocalizedString("Resume the Game", comment: "AX label pause button.")
        } else {
            pauseButton.accessibilityLabel = NSLocalizedString("Pause the Game", comment: "AX label pause button.")
        }
    }
    
    // MARK: - Action Methods
    
    @objc func setPaddleSize(sender: UISlider) {
        delegate?.accessibilityControls(self, paddleSizeChanged: sender.value)
    }
    
    @objc func setSpeed(sender: UISlider) {
        delegate?.accessibilityControls(self, gameSpeedChanged: sender.value)
    }
    
    @objc func toggleEnableCollisionAnnouncements(sender: UISwitch) {
        enableCollisionAnnouncements = sender.isOn
        delegate?.accessibilityControls(self, enableCollisionAnnouncements: enableCollisionAnnouncements)
    }
    
    @objc func togglePauseDuringAnnouncements(sender: UISwitch) {
        pauseDuringAnnouncements = sender.isOn
        delegate?.accessibilityControls(self, pauseDuringAnnouncements: pauseDuringAnnouncements)
    }
    
    @objc func togglePauseGameSwitch(sender: UISwitch) {
        let isPaused = sender.isOn
        delegate?.accessibilityControls(self, pauseGame: isPaused)
    }
    
    @objc func togglePauseGame(sender: UIResponder) {
        guard let button = sender as? UIButton else { return }
        button.isSelected = !button.isSelected
        updatePauseButtonAX()
        let isPaused = button.isSelected
        delegate?.accessibilityControls(self, pauseGame: isPaused)
    }
    
    @objc func resetValues(sender: UIResponder) {
        paddleSizeSlider?.value = 1.0
        speedSlider?.value = 1.0
        delegate?.accessibilityControls(self, paddleSizeChanged: 1.0)
        delegate?.accessibilityControls(self, gameSpeedChanged: 1.0)
    }
    
    
    // MARK: - Private Methods
    private func updateControls() {
        speedSlider?.value = gameSpeed
        paddleSizeSlider?.value = paddleSize
        enableCollisionAnnouncementsSwitch?.isOn = enableCollisionAnnouncements
                
        if !enableCollisionAnnouncements {
            pauseDuringAnnouncementsSwitch?.isOn = false
            pauseDuringAnnouncementsSwitch?.isEnabled = false
        } else {
            pauseDuringAnnouncementsSwitch?.isOn = pauseDuringAnnouncements
            pauseDuringAnnouncementsSwitch?.isEnabled = true
        }
        
        pauseButton?.isSelected = isGamePaused
    }
}
