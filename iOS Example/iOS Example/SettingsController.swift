//
//  SettingsController.swift
//  iOS Example
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
import Image360

class SettingsController: UIViewController {

    @IBOutlet var inertiaSegmentedControl: UISegmentedControl!
    @IBOutlet var pictureSegmentedControl: UISegmentedControl!
    @IBOutlet var isOrientationViewHiddenSwitch: UISwitch!
    @IBOutlet var isDeviceMotionControlEnabledSwitch: UISwitch!

    @IBOutlet var saveButton: UIBarButtonItem!

    var inertia: Inertia = .none
    var pictureIndex: Int = 0
    var isOrientationViewHidden: Bool = false
    var isDeviceMotionControlEnabled: Bool = false

    private var initInertia: Inertia!
    private var initPictureIndex: Int!
    private var initIsOrientationViewHidden: Bool!
    private var initIsDeviceMotionControlEnabled: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        switch inertia {
        case .none:
            inertiaSegmentedControl.selectedSegmentIndex = 0
        case .short:
            inertiaSegmentedControl.selectedSegmentIndex = 1
        case .long:
            inertiaSegmentedControl.selectedSegmentIndex = 2
        }
        isOrientationViewHiddenSwitch.isOn = isOrientationViewHidden
        isDeviceMotionControlEnabledSwitch.isOn = isDeviceMotionControlEnabled

        initInertia = inertia
        initPictureIndex = pictureIndex
        initIsOrientationViewHidden = isOrientationViewHidden
        initIsDeviceMotionControlEnabled = isDeviceMotionControlEnabled
        pictureSegmentedControl.selectedSegmentIndex = pictureIndex
    }

    @IBAction func inertiaSegmentChanged(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: inertia = .none
        case 1: inertia = .short
        case 2: inertia = .long
        default:
            assertionFailure("Unexpected selected segment index")
        }
        saveButton.isEnabled = valuesChanged
    }

    @IBAction func pictureSegmentChanged(sender: UISegmentedControl) {
        pictureIndex = sender.selectedSegmentIndex
        saveButton.isEnabled = valuesChanged
    }
    
    @IBAction func isOrientationViewHiddenSwitched(sender: UISwitch) {
        isOrientationViewHidden = sender.isOn
        saveButton.isEnabled = valuesChanged
    }
    
    @IBAction func isDeviceMotionControlEnabledSwitched(sender: UISwitch) {
        isDeviceMotionControlEnabled = sender.isOn
        saveButton.isEnabled = valuesChanged
    }

    private var valuesChanged: Bool {
        if inertia != initInertia {
            return true
        } else if pictureIndex != initPictureIndex {
            return true
        } else if initIsOrientationViewHidden != isOrientationViewHidden {
            return true
        } else if initIsDeviceMotionControlEnabled != isDeviceMotionControlEnabled {
            return true
        } else {
            return false
        }
    }
}
