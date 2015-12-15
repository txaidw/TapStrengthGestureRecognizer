//
//  MultiTapStrengthRecognizerView.swift
//  TapStrengthGestureRecognizer
//
//  Created by Txai Wieser on 15/12/15.
//  Copyright © 2015 Txai Wieser. All rights reserved.
//

import UIKit
import CoreMotion

class MultiTapStrengthRecognizerView: UIView, GlobalCMMotionManagerNotificationReceiver {
    weak var delegate:TapStrengthGestureRecognizerDelegate?
    var listOfTouches:[UIStrengthTouch] = []
    var pressureValues:[Float] = []

    
    // MARK: Default Initializers
    
    func setup() {
        self.multipleTouchEnabled = true
        GlobalCMMotionManager.registerForNotification(self)
    }
    deinit {
        GlobalCMMotionManager.unregisterForNotification(self)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    func didRecognizeTapStrength(touch:UIStrengthTouch) {
        print(touch.strength)
    }
    
    // MARK: MotionManager Notification
    
    func motionManagerNotification() {
        accelerateNotification(GlobalCMMotionManager.$.accelerometerData?.acceleration ?? CMAcceleration(x: 0, y: 0, z: 0))
    }
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.listOfTouches.appendContentsOf(touches.map { return UIStrengthTouch(touch: $0) })
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if let t = touches { self.listOfTouches.removeObjectsInArray(t.map { return UIStrengthTouch(touch: $0) }) }
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.listOfTouches.removeObjectsInArray(touches.map { return UIStrengthTouch(touch: $0) })
    }


    func accelerateNotification(acceleration:CMAcceleration) {
        if pressureValues.count >= 50 { pressureValues.removeFirst() }
        pressureValues.append(Float(acceleration.z))
        let average = pressureValues.reduce(0) { $0 + $1 } / Float(pressureValues.count)
        
        for touch in listOfTouches {
            if touch.attempts > 0 {
                
                // calculate average pressure
                
                // start with most recent past pressure sample
                if touch.attempts == 3 {
                    let mostRecent = pressureValues[pressureValues.count-2];
                    touch.strength = fabs(average - mostRecent);
                }
                
                // caluculate pressure as difference between average and current acceleration
                let diff = fabs(average - Float(acceleration.z));
                if (touch.strength < diff) { touch.strength = diff; }
                touch.attempts--;
                
                if (touch.attempts == 0) {
                    didRecognizeTapStrength(touch)
                    self.listOfTouches.removeObject(touch)
                }
            }
        }
    }
}

// MARK: Extra Types

protocol TapStrengthGestureRecognizerDelegate:class {
    func didReceiveTap(strength:Double)
}

class UIStrengthTouch: Equatable {
    let touch:UITouch
    var strength:Float
    var attempts:Int
    
    init(touch: UITouch, strength: Float = 0, attempts: Int = 3) {
        self.touch = touch
        self.strength = strength
        self.attempts = attempts
    }
}

func ==(lhs: UIStrengthTouch, rhs: UIStrengthTouch) -> Bool {
    return lhs.touch == rhs.touch
}

protocol GlobalCMMotionManagerNotificationReceiver:class {
    func motionManagerNotification()
}

class GlobalCMMotionManager {
    static let sharedInstance = GlobalCMMotionManager()
    static var $:CMMotionManager { return sharedInstance.motionManager }
    let motionManager = CMMotionManager()
    let GLOBAL_CM_MOTION_MANAGER = "GLOBAL_CM_MOTION_MANAGER"
    private init() {
        motionManager.accelerometerUpdateInterval = 0.001/60.0
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { [weak self] (data: CMAccelerometerData?, error:NSError?) -> Void in
            if let me = self {
                NSNotificationCenter.defaultCenter().postNotificationName(me.GLOBAL_CM_MOTION_MANAGER, object: me.motionManager)
            }
        }
    }
    
    static func registerForNotification(object:GlobalCMMotionManagerNotificationReceiver) {
        NSNotificationCenter.defaultCenter().addObserver(object, selector: Selector("motionManagerNotification"), name: self.sharedInstance.GLOBAL_CM_MOTION_MANAGER, object: nil)
    }
    static func unregisterForNotification(object:GlobalCMMotionManagerNotificationReceiver) {
        NSNotificationCenter.defaultCenter().removeObserver(object)
    }
}

// Swift 2 Array Extension
extension Array where Element: Equatable {
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
    
    mutating func removeObjectsInArray(array: [Element]) {
        for object in array {
            self.removeObject(object)
        }
    }
}