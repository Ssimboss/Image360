//
//  ViewController.swift
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

private let picture1URL = Bundle.main.url(forResource: "picture1", withExtension: "jpg")!
private let picture2URL = Bundle.main.url(forResource: "picture2", withExtension: "jpg")!

class ViewController: UIViewController {

    @IBOutlet var image360Controller: Image360Controller!

    @IBOutlet var pictureSegmentedControl: UISegmentedControl!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier{
            case "image360":
                if let destination = segue.destination as? Image360Controller {
                    self.image360Controller = destination
                }
            case "settings":
                if let destination = segue.destination as? SettingsController {
                    destination.inertia = image360Controller.inertia
                }
            default:
                ()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if pictureSegmentedControl.selectedSegmentIndex < 0 {
            pictureSegmentedControl.selectedSegmentIndex = 0
            segmentChanged(sender: pictureSegmentedControl)
        }
    }

    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {
        guard let settingsController = segue.source as? SettingsController else {
            assertionFailure("Unexpected controller's type")
            return
        }
        image360Controller.inertia = settingsController.inertia
    }

    @IBAction func segmentChanged(sender: UISegmentedControl) {
        let pictureURL: URL
        switch sender.selectedSegmentIndex {
        case 0:
            pictureURL = picture1URL
        case 1:
            pictureURL = picture2URL
        default:
            assertionFailure("Unexpected selected segment index")
            return
        }

        do {
            let data = try Data(contentsOf: pictureURL)
            if let image = UIImage(data: data) {
                self.image360Controller.image = image
            } else {
                NSLog("liveView - frameData is not image")
            }
        } catch  {

        }

    }
}
