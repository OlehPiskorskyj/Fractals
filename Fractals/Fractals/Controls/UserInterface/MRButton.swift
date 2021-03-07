//
//  MRButton.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 09/02/2021.
//

import UIKit

class MRButton: UIButton {
    
    // MARK: - props
    private let longPrestGR = UILongPressGestureRecognizer()
    private var timer: Timer? = nil
    
    public var longPressAction: (() -> ())? = nil
    
    public var defaultTouchesEnabled: Bool = false {
        didSet {
            longPrestGR.cancelsTouchesInView = !defaultTouchesEnabled
        }
    }
    
    // MARK: - ctors
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.internalInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.internalInit()
    }
    
    func internalInit() {
        let borderColor = self.backgroundColor
        
        self.backgroundColor = .clear
        self.layer.borderWidth = 0.5
        self.layer.borderColor = borderColor?.cgColor
        
        longPrestGR.addTarget(self, action: #selector(buttonLongPress(gesture:)))
        longPrestGR.minimumPressDuration = 0.0
        longPrestGR.cancelsTouchesInView = !defaultTouchesEnabled
        self.addGestureRecognizer(longPrestGR)
    }
    
    // MARK: - events
    @objc func buttonLongPress(gesture: UILongPressGestureRecognizer) {
        if (gesture.state == .began) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self] (timer) in
                self?.longPressAction?()
            })
        } else if (gesture.state == .ended) {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
}
