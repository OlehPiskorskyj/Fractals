//
//  JuliaScreen.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 12/02/2021.
//

import UIKit

class JuliaScreen: UIViewController {

    // MARK: - props
    @IBOutlet weak var viewJulia: Julia!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnAdd: MRButton!
    @IBOutlet weak var btnMinus: MRButton!
    
    // MARK: - view controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
        
        btnMinus.longPressAction = { [weak self] in
            self?.viewJulia.zoom -= 0.05
        }
        
        btnAdd.longPressAction = { [weak self] in
            self?.viewJulia.zoom += 0.05
        }
    }
    
    // MARK: - events
    @IBAction func btnCloseClick(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
