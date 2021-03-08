//
//  JuliaScreen.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 12/02/2021.
//

import UIKit

class JuliaScreen: UIViewController {

    // MARK: - props
    @IBOutlet weak var viewGamePad: MRGamePad!
    @IBOutlet weak var viewJulia: Julia!
    
    // MARK: - view controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewGamePad.closeClicked = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        viewGamePad.minusAction = { [weak self] in
            self?.viewJulia.zoom -= 0.05
        }
        
        viewGamePad.addAction = { [weak self] in
            self?.viewJulia.zoom += 0.05
        }
        
        viewGamePad.rotationChandeAction = { [weak self] in
            self?.rotationSwichChanged()
        }
    }
    
    @IBAction func removeGamePadClick(_ sender: Any) {
        viewGamePad.alpha = 0.0
    }
    
    // MARK: - other methods
    func rotationSwichChanged() {
        viewJulia.rotating = !viewJulia.rotating
    }
}
