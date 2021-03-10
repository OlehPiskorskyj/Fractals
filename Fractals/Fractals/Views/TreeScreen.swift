//
//  TreeScreen.swift
//  Fractals
//
//  Created by Oleh Piskorskyj on 08/03/2021.
//

import UIKit

class TreeScreen: UIViewController {
    
    // MARK: - props
    @IBOutlet weak var viewGamePad: MRGamePad!
    @IBOutlet weak var viewTree: Tree!
    @IBOutlet weak var imgTemp: UIImageView!
    
    // MARK: - view controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewGamePad.closeClicked = { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true)
        }
        
        viewGamePad.minusAction = { [weak self] in
            self?.viewTree.zoom -= 0.05
        }
        
        viewGamePad.addAction = { [weak self] in
            self?.viewTree.zoom += 0.05
        }
        
        viewGamePad.rotationChandeAction = { [weak self] in
            self?.rotationSwichChanged()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.imgTemp.image = viewTree.imageData
    }
    
    
    // MARK: - other methods
    func rotationSwichChanged() {
        viewTree.rotating = !viewTree.rotating
    }
    
}
