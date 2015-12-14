//
//  ViewController.swift
//  TapStrengthRecognizer
//
//  Created by Txai Wieser on 13/12/15.
//  Copyright © 2015 Txai Wieser. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var header: UILabel!
    @IBOutlet weak var body: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        body.addGestureRecognizer(TapStrengthRecognizer(delegate: self))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: TapStrengthRecognizerDelegate {
    func didReceiveTap(strength: Double) {
        print(strength)
    }
}