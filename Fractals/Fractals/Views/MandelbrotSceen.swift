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
    @IBOutlet weak var viewGamePad: MRGamePad!
    
    // MARK: - view controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewGamePad.closeClicked = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        viewGamePad.minusAction = { [weak self] in
            self?.viewMandelbrot.zoom -= 0.05
        }
        
        viewGamePad.addAction = { [weak self] in
            self?.viewMandelbrot.zoom += 0.05
        }
        
        viewGamePad.rotationChandeAction = { [weak self] in
            self?.rotationSwichChanged()
        }
    }
    
    // MARK: - other methods
    func rotationSwichChanged() {
        viewMandelbrot.rotating = !viewMandelbrot.rotating
    }
}
