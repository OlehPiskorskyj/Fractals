//
//  Main.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 07/02/2021.
//

import UIKit

class Main: UIViewController {
    
    // MARK: - props
    @IBOutlet weak var btnMandelbrot: MRButton!
    @IBOutlet weak var btnJulia: MRButton!
    @IBOutlet weak var btnTree: MRButton!
    
    // MARK: - view controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnMandelbrot.defaultTouchesEnabled = true
        btnJulia.defaultTouchesEnabled = true
        btnTree.defaultTouchesEnabled = true
    }
}
