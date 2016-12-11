//
//  ViewController.swift
//  IOSLab3A
//
//  Created by Waleed Hassan on 08/12/16.
//  Copyright © 2016 Scalman & Martin. All rights reserved.
//  This code is inspired by these sources:
//  http://stackoverflow.com/questions/2317428/android-i-want-to-shake-it/11972661#11972661
//  http://stackoverflow.com/questions/25263049/swift-ios-date-as-milliseconds-double-or-uint64

import UIKit
import CoreMotion

class ViewController: UIViewController {

    
    @IBOutlet weak var zLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    
    private let manager = CMMotionManager()
    private let FILTER = 0.9
    private let ACCEL_FILTER = 0.9
    private let π = M_PI
    private var startTime:Double = 0.0
    private var countOfShakes = 0
    
    private var tiltFilter:[Double] = [0.0,0.0,0.0]
    private var tiltAngle:[Double] = [0.0,0.0,0.0]
    private var gravityFilter:[Double] = [0.0,0.0,0.0]
    private var linearAcceleration:[Double] = [0.0,0.0,0.0]
    private var X = 0
    private var Y = 1
    private var Z = 2

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if manager.isAccelerometerAvailable{
            manager.accelerometerUpdateInterval = 0.1
            manager.startAccelerometerUpdates()
        }
        
        tiltPhone()

    }
    
    private let MIN_SHAKE_ACCELERATION = 1.0
    private let MAX_SHAKE_DURATION = 1.0
    private let MIN_MOVEMENTS = 3
    var timer = Timer()
    var timer2 = Timer()
    var isShaking = false
    
    private func tiltPhone(){
        let queue = OperationQueue.main
        manager.startAccelerometerUpdates(to: queue) {
            (data, error) in

            self.filterTilt(x:data!.acceleration.x,y:data!.acceleration.y,z:data!.acceleration.z)
            self.calculateAngle()
            self.printAngles()
            
            self.filterShakeAction(x:data!.acceleration.x,y:data!.acceleration.y,z:data!.acceleration.z)
            self.removeGravityXYZ(x:data!.acceleration.x,y:data!.acceleration.y,z:data!.acceleration.z)

            
            let maxLinearAcceleration = self.getMaxCurrentGForceAccel()
            
            if maxLinearAcceleration > self.MIN_SHAKE_ACCELERATION {
                if(self.timer2.isValid){
                    self.timer2.invalidate()
                }
                if !self.timer.isValid{
                    self.timer = Timer.scheduledTimer(timeInterval: self.MAX_SHAKE_DURATION, target:self, selector: #selector(self.changeColor), userInfo: nil, repeats: false)
                }
            } else {
                if !self.timer2.isValid{
                    self.timer2 = Timer.scheduledTimer(timeInterval: 0.5, target:self, selector: #selector(self.inTime), userInfo: nil, repeats: false)
                }
                if self.timer.isValid {
                    self.countOfShakes += 1
                }
            }

        }
    }
    func inTime(){
        if(self.timer.isValid){
            self.timer.invalidate()
            countOfShakes = 0
        }
    }
    
    @IBOutlet var background: UIView!
    
    func changeColor(){
        
        print(countOfShakes)
        if self.countOfShakes <= self.MIN_MOVEMENTS {
            timer.invalidate()
            countOfShakes = 0
            return
        }
    
        let rand = arc4random_uniform(7)
        var color:UIColor? = nil
            
        switch rand {
        case 0:
            color = UIColor.black
        case 1:
            color = UIColor.darkGray
        case 2:
            color = UIColor.green
        case 3:
            color = UIColor.yellow
        case 4:
            color = UIColor.orange
        case 5:
            color = UIColor.purple
        case 6:
            color = UIColor.magenta
        default:
            color = UIColor.blue
        }
        
        background.backgroundColor = color
        
        timer.invalidate()
        countOfShakes = 0
        
    }
    /// The three underlaying methods is to detect tilting. Adding a filter,
    /// calculating an angle and printing.
    private func filterTilt(x:Double,y:Double,z:Double){
        
        self.tiltFilter[X] = (self.FILTER * self.tiltFilter[X]) + ((1 - self.FILTER) * x)
        self.tiltFilter[Y] = (self.FILTER * self.tiltFilter[Y]) + ((1 - self.FILTER) * y)
        self.tiltFilter[Z] = (self.FILTER * self.tiltFilter[Z]) + ((1 - self.FILTER) * z)
    }
    private func calculateAngle(){
        tiltAngle[X] = atan((self.tiltFilter[X]) / (sqrt(pow(self.tiltFilter[Y], 2) + pow(self.tiltFilter[Z], 2))))
        tiltAngle[Y] = atan((self.tiltFilter[Y]) / (sqrt(pow(self.tiltFilter[X], 2) + pow(self.tiltFilter[Z], 2))))
        tiltAngle[Z] = atan(sqrt(pow(self.tiltFilter[X],2) + pow(self.tiltFilter[Y],2)) / self.tiltFilter[Z])

    }
    private func printAngles(){
        
        let x = Int((tiltAngle[X] * 180) / π)
        let y = Int((tiltAngle[Y] * 180) / π)
        let z = Int((tiltAngle[Z] * 180) / π)
//        print("X:  \(x)")
//        print("Y:  \(y)")
//        print("Z:  \(z)")
        xLabel.text = "X:" + String(x)
        yLabel.text = "Y:" + String(y)
        zLabel.text = "Z:" + String(z)
    }
    
    /// Gravity components of x, y, and z acceleration
    private func filterShakeAction(x:Double,y:Double,z:Double){
        self.gravityFilter[X] = (self.ACCEL_FILTER * self.gravityFilter[X]) + ((1 - self.ACCEL_FILTER) * x)
        self.gravityFilter[Y] = (self.ACCEL_FILTER * self.gravityFilter[Y]) + ((1 - self.ACCEL_FILTER) * y)
        self.gravityFilter[Z] = (self.ACCEL_FILTER * self.gravityFilter[Z]) + ((1 - self.ACCEL_FILTER) * z)
    }
    /// Linear acceleration along the x, y, and z axes (gravity effects removed)
    private func removeGravityXYZ(x:Double,y:Double,z:Double){
        self.linearAcceleration[X] = x - self.gravityFilter[X]
        self.linearAcceleration[Y] = y - self.gravityFilter[Y]
        self.linearAcceleration[Z] = z - self.gravityFilter[Z]
    }
    
    /// Checks which accel is the greatest by comparing all three forces.
    /// Return value is the greatest.
    private func getMaxCurrentGForceAccel() -> Double{
        
        // Start by setting the value to the x value
        var maxLinearAcceleration:Double = linearAcceleration[X]
        
        // Check if the y value is greater
        if linearAcceleration[Y] > maxLinearAcceleration {
            maxLinearAcceleration = linearAcceleration[Y]
        }
        
        // Check if the z value is greater
        if linearAcceleration[Z] > maxLinearAcceleration {
            maxLinearAcceleration = linearAcceleration[Z]
        }
        
        // Return the greatest value
        return maxLinearAcceleration;
    }
    
    private func resetShakeDetection() {
        self.startTime = 0
        self.countOfShakes = 0
    }

}

