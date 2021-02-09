//
//  MRButton.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 09/02/2021.
//

import UIKit

class MRButton: UIButton {
    
    // MARK: - props
    private var timer: Timer? = nil
    
    public var longPressAction: (() -> ())? = nil
    
    // MARK: - ctors
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.internalInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.internalInit()
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
    
    // MARK: - other methods
    func internalInit() {
        let borderColor = self.backgroundColor
        
        self.backgroundColor = .clear
        self.layer.borderWidth = 0.5
        self.layer.borderColor = borderColor?.cgColor
        
        let longPrestGR = UILongPressGestureRecognizer()
        longPrestGR.addTarget(self, action: #selector(buttonLongPress(gesture:)))
        longPrestGR.minimumPressDuration = 0.0
        longPrestGR.cancelsTouchesInView = true
        self.addGestureRecognizer(longPrestGR)
    }
}
