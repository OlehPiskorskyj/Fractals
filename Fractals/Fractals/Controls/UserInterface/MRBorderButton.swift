//
//  MRBorderButton.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 17/03/2021.
//

import UIKit

@IBDesignable class MRBorderButton: UIButton {
    
    // MARK: - props
    @IBInspectable var borderColor: UIColor = .white {
        didSet {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
}
