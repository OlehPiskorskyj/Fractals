//
//  Mandelbrot.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 07/02/2021.
//

import UIKit

class MandelbrotSceen: UIViewController {
    
    // MARK: - props
    @IBOutlet weak var viewMandelbrot: Mandelbrot!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnMinus: MRButton!
    @IBOutlet weak var btnAdd: MRButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
        
        btnMinus.longPressAction = { [weak self] in
            self?.viewMandelbrot.zoom -= 0.05
        }
        
        btnAdd.longPressAction = { [weak self] in
            self?.viewMandelbrot.zoom += 0.05
        }
    }
    
    // MARK: - events
    @IBAction func btnCloseClick(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
