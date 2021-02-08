//
//  Mandelbrot.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 07/02/2021.
//

import UIKit

class MandelbrotSceen: UIViewController {
    
    // MARK: - props
    @IBOutlet weak var btnClose: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 1.0
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
    }
    
    // MARK: - events2
    @IBAction func btnCloseClick(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
