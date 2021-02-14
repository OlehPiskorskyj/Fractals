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
    
    public var closeClicked: (() -> ())? = nil
    
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
    
    // MARK: - other methods
    private func internalInit() {
        Bundle.main.loadNibNamed("MRGamePad", owner: self, options: nil)
        self.addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
        
        /*
        btnTemplate.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnRepeat.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnMonth.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnDay.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnWeekDay.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnStart.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        btnEnd.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        */
    }

}
