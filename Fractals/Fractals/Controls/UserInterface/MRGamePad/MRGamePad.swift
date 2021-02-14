//
//  MRGamePad.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 14/02/2021.
//

import UIKit

class MRGamePad: UIView {
    
    // MARK: - props
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnMinus: MRButton!
    @IBOutlet weak var btnAdd: MRButton!
    
    public var closeClicked: (() -> ())? = nil
    public var minusAction: (() -> ())? = nil
    public var addAction: (() -> ())? = nil
    public var rotationChandeAction: (() -> ())? = nil
    
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
    @IBAction func btnCloseClick(_ sender: Any) {
        self.closeClicked?()
    }
    
    @IBAction func swchRotationChanged(_ sender: Any) {
        self.rotationChandeAction?()
    }
    
    // MARK: - other methods
    private func internalInit() {
        Bundle.main.loadNibNamed("MRGamePad", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
        
        btnMinus.longPressAction = { [weak self] in
            self?.minusAction?()
        }
        
        btnAdd.longPressAction = { [weak self] in
            self?.addAction?()
        }
    }
}
