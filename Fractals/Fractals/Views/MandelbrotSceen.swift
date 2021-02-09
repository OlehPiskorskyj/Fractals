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
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var btnMinus: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
        
        btnAdd.backgroundColor = .clear
        btnAdd.layer.borderWidth = 0.5
        btnAdd.layer.borderColor = UIColor.systemBlue.cgColor
        
        btnMinus.backgroundColor = .clear
        btnMinus.layer.borderWidth = 0.5
        btnMinus.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    // MARK: - events
    @IBAction func btnCloseClick(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    @IBAction func btnAddClick(_ sender: Any) {
        viewMandelbrot.zoom += 1.0
    }
    
    @IBAction func btnMinusClick(_ sender: Any) {
        viewMandelbrot.zoom -= 1.0
    }
}
