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
    
    // MARK: - view controller lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnMandelbrot.defaultTouchesEnabled = true
        btnJulia.defaultTouchesEnabled = true
    }
    
    // MARK: - events
    @IBAction func btnMandelbrotClick(_ sender: Any) {
        let mandelbrot = self.storyboard!.instantiateViewController(withIdentifier: "MandelbrotSceen") as! MandelbrotSceen
        self.navigationController!.pushViewController(mandelbrot, animated: true)
    }
    
    @IBAction func btnJuliaClick(_ sender: Any) {
        let julia = self.storyboard!.instantiateViewController(withIdentifier: "JuliaScreen") as! JuliaScreen
        self.navigationController!.pushViewController(julia, animated: true)
    }
}
