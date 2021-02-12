//
//  JuliaScreen.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 12/02/2021.
//

import UIKit

class JuliaScreen: UIViewController {

    // MARK: - props
    @IBOutlet weak var btnClose: UIButton!
    
    // MARK: - view controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnClose.backgroundColor = .clear
        btnClose.layer.borderWidth = 0.5
        btnClose.layer.borderColor = UIColor.systemRed.cgColor
    }
    
    // MARK: - events
    @IBAction func btnCloseClick(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
}
