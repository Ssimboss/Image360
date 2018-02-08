//
//  MotionController.swift
//  Image360
//
//  Copyright © 2017 Andrew Simvolokov. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import CoreMotion

/// ## MotionController
/// Motion controller is responsible for `Image360View` rotation control via device motions.
final class MotionController: Controller {
    /// `Image360View` which is under control of `MotionController`.
    weak var imageView: Image360View?
    /// Inertia of motions. Is ignored at the moment.
    var inertia: Float = 0.0
    
    /// Default `MotionController` constructor.
    init() {
        isEnabled = motionManager.isDeviceMotionAvailable
        if isEnabled {
            enableDeviceMotionControl()
        }
    }
    
    /// MARK: Motion Management
    private var motionManager = CMMotionManager()
    
    private func enableDeviceMotionControl() {
        motionManager.deviceMotionUpdateInterval = 0.02
        let queue = OperationQueue()
        motionManager.startDeviceMotionUpdates(to: queue, withHandler: deviceDidMove)
    }
    
    private func disableDeviceMotionControl() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    /// If this flag is `true` then `Image360View`-orientation could be controled with device motions.
    var isEnabled: Bool {
        didSet {
            if isEnabled && !motionManager.isDeviceMotionAvailable {
                NSLog("Image360: Device motion is not available on this device")
                isEnabled = false
            } else if oldValue != isEnabled {
                isEnabled ? enableDeviceMotionControl() : disableDeviceMotionControl()
            }
        }
    }
    
    private var _lastAttitude: CMAttitude?
    private var _lastOrientation: UIInterfaceOrientation?
    
    /// Device Motion Updates Handler
    /// - parameter data: New data of device motion.
    /// - parameter error: Error catched by device.
    private func deviceDidMove(data: CMDeviceMotion?, error: Error?) {
        guard let data = data else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            let currentOrientation = UIApplication.shared.statusBarOrientation
            guard let lastAttitude = self?._lastAttitude, let lastOrientation = self?._lastOrientation, currentOrientation == lastOrientation else {
                self?._lastAttitude = data.attitude
                self?._lastOrientation = currentOrientation
                return
            }
            self?._lastAttitude = data.attitude.copy() as? CMAttitude
            
            data.attitude.multiply(byInverseOf: lastAttitude)
            
            let diffXZ: Float
            let diffY: Float
            
            switch lastOrientation {
            case .portrait:
                diffXZ = -Float(data.attitude.roll)
                diffY = Float(data.attitude.pitch)
            case .portraitUpsideDown:
                diffXZ = Float(data.attitude.roll)
                diffY = -Float(data.attitude.pitch)
            case .landscapeLeft:
                diffXZ = Float(data.attitude.pitch)
                diffY = Float(data.attitude.roll)
            case .landscapeRight:
                diffXZ = -Float(data.attitude.pitch)
                diffY = -Float(data.attitude.roll)
            default:
                return
            }
            self?.rotate(diffx: diffXZ, diffy: diffY)
        }
    }
    
    /// Rotation method
    /// - parameter diffx: Rotation amount (y axis)
    /// - parameter diffy: Rotation amount (xy plane)
    private func rotate(diffx: Float, diffy: Float) {
        guard let imageView = imageView else {
            return
        }
        imageView.setRotationAngleXZ(newValue: imageView.rotationAngleXZ + diffx)
        imageView.setRotationAngleY(newValue: imageView.rotationAngleY + diffy)
    }
}
