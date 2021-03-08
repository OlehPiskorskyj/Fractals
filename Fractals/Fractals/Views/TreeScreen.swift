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
    
    // MARK: - other methods
    func rotationSwichChanged() {
        viewTree.rotating = !viewTree.rotating
    }
    
}
