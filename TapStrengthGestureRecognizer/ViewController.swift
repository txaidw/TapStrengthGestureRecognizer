//
//  ViewController.swift
//  TapStrengthGestureRecognizer
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
        body.addGestureRecognizer(TapStrengthGestureRecognizer(delegate: self))
        header.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: TapStrengthGestureRecognizerDelegate {
    func didReceiveTap(strength: Double) {
        print(strength)
        header.text = String(format: "%.3f", arguments: [strength])
        header.backgroundColor = UIColor.redColor().colorWithAlphaComponent(CGFloat(strength))
    }
}