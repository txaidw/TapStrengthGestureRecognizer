//
//  TapStrengthRecognizer.swift
//  TapStrengthRecognizer
//
//  Created by Txai Wieser on 13/12/15.
//  Copyright © 2015 Txai Wieser. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass
import CoreMotion

protocol TapStrengthRecognizerDelegate:class {
    func didReceiveTap(strength:Double)
}

enum TapStrength:Double {
    case None = 0.0
    case Light = 0.3
    case Medium = 0.4
    case Hard = 0.6
    case Infinite = 2.0
}

class TapStrengthRecognizer: UIGestureRecognizer, GlobalCMMotionManagerNotificationReceiver {
    weak var tapDelegate:TapStrengthRecognizerDelegate?
    
    var strengthRange:(min:TapStrength, max:TapStrength) = (.None, .Infinite)
    var currentStrength:Double = TapStrength.None.rawValue
    
    
    var setNextPressureValue = 0
    
    init(delegate:TapStrengthRecognizerDelegate) {
        tapDelegate = delegate
        super.init(target: nil, action: nil)
        addTarget(self, action: Selector("didTapView:"))
        GlobalCMMotionManager.registerForNotification(self)
    }
    func motionManagerNotification() {
        accelerateNotification(GlobalCMMotionManager.$.accelerometerData?.acceleration ?? CMAcceleration(x: 0, y: 0, z: 0))
    }
    func didTapView(recognizer:TapStrengthRecognizer) {
        tapDelegate?.didReceiveTap(recognizer.currentStrength)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        setNextPressureValue = 3
        state = .Possible
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
    }
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        //setNextPressureValue = KNumberOfPressureSamples;
        print("in touc ended laa")
        state = .Possible
    }
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        state = .Failed
    }
    override func reset() {
        currentStrength = TapStrength.None.rawValue
        setNextPressureValue = 0
        pressureValues.removeAll()
    }
    
    var pressureValues:[Double] = []
    
    func accelerateNotification(acceleration:CMAcceleration) {
        // set current pressure value
        if pressureValues.count >= 50 { pressureValues.removeFirst() }
        pressureValues.append(acceleration.z)
        
        if (self.setNextPressureValue > 0) {
            
            // calculate average pressure
            let average = pressureValues.reduce(0) { $0 + $1 } / Double(pressureValues.count)
            
            // start with most recent past pressure sample
            if (setNextPressureValue == 3) {
                let mostRecent = pressureValues[pressureValues.count-2];
                currentStrength = fabs(average - mostRecent);
            }
            
            // caluculate pressure as difference between average and current acceleration
            let diff = fabs(average - acceleration.z);
            if (currentStrength < diff) { currentStrength = diff; }
            setNextPressureValue--;
            
            if (setNextPressureValue == 0) {
                if (currentStrength >= strengthRange.min.rawValue && currentStrength <= strengthRange.max.rawValue) {
                    state = .Recognized
                } else {
                    state = .Failed
                }
            }
        }
    }
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
