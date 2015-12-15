//
//  TapStrengthGestureRecognizer.swift
//  TapStrengthGestureRecognizer
//
//  Created by Txai Wieser on 13/12/15.
//  Copyright © 2015 Txai Wieser. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import CoreMotion

protocol TapStrengthGestureRecognizerDelegate:class {
    func didReceiveTap(strength:Double)
}

enum TapStrength:Float {
    case None = 0.0
    case Light = 0.3
    case Medium = 0.4
    case Hard = 0.6
    case Infinite = 2.0
}

class TapStrengthGestureRecognizer: UIGestureRecognizer, GlobalCMMotionManagerNotificationReceiver {
    weak var tapDelegate:TapStrengthGestureRecognizerDelegate?
    
    var strengthRange:(min:TapStrength, max:TapStrength) = (.None, .Infinite)
    
    
    init(delegate:TapStrengthGestureRecognizerDelegate) {
        tapDelegate = delegate
        super.init(target: nil, action: nil)
        addTarget(self, action: Selector("didTapView:"))
        GlobalCMMotionManager.registerForNotification(self)
    }
    deinit {
        GlobalCMMotionManager.unregisterForNotification(self)
    }
    func motionManagerNotification() {
        accelerateNotification(GlobalCMMotionManager.$.accelerometerData?.acceleration ?? CMAcceleration(x: 0, y: 0, z: 0))
    }
    func didTapView(recognizer:TapStrengthGestureRecognizer) {
//        tapDelegate?.didReceiveTap(recognizer.currentStrength)
        listOfTouches.forEach { print("t: \($0.force)") }
    }


    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        print("====================")
        self.listOfTouches.appendContentsOf(touches.map { return UIStrengthTouch(touch: $0) })
        state = .Possible
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        state = .Possible
        if let t = touches { self.listOfTouches.removeObjectsInArray(t.map { return UIStrengthTouch(touch: $0) }) }
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        state = .Failed
        self.listOfTouches.removeObjectsInArray(touches.map { return UIStrengthTouch(touch: $0) })
    }
    override func reset() {
        listOfTouches.removeAll()
        pressureValues.removeAll()
    }
    
    var pressureValues:[Float] = []
    
    var listOfTouches:[UIStrengthTouch] = []

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
                    touch.force = fabs(average - mostRecent);
                }
                
                // caluculate pressure as difference between average and current acceleration
                let diff = fabs(average - Float(acceleration.z));
                if (touch.force < diff) { touch.force = diff; }
                touch.attempts--;
                
                if (touch.attempts == 0) {
                    if (touch.force >= strengthRange.min.rawValue && touch.force <= strengthRange.max.rawValue) {
                        state = .Recognized
                    } else {
                        state = .Failed
                    }
                }
            }
        }
    }
}

class UIStrengthTouch: Equatable {
    let touch:UITouch
    var force:Float
    var attempts:Int
    
    init(touch: UITouch, force: Float = 0, attempts: Int = 3) {
        self.touch = touch
        self.force = force
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