//
//  Main.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 07/02/2021.
//

import UIKit

class Main: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - events
    @IBAction func btnMandelbrotClick(_ sender: Any) {
        let mandelbrot = self.storyboard!.instantiateViewController(withIdentifier: "MandelbrotSceen") as! MandelbrotSceen
        self.navigationController!.pushViewController(mandelbrot, animated: true)
    }
}
