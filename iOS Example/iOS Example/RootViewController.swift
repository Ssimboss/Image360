//
//  RootViewController.swift
//  iOS Example
//
//  Created by Andrew Simvolokov on 16.03.17.
//  Copyright © 2017 Andrew Simvolokov. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    @IBAction func buttonTapped(sender: UIButton) {
        sender.isEnabled = false
        activityIndicatorView.startAnimating()
        DispatchQueue.global(qos: .default).async {
            let url = URL(string: "https://d36tnp772eyphs.cloudfront.net/blogs/1/2006/11/360-panorama-matador-seo.jpg")!
            let data = try? Data.init(contentsOf: url)
            DispatchQueue.main.async {
                if let image = data.flatMap(UIImage.init(data:)) {
                    self.performSegue(withIdentifier: "image360Present", sender: image)
                } else {
                    let alertController = UIAlertController(title: "Error!", message: "Something went wrong", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                }
                self.activityIndicatorView.stopAnimating()
                sender.isEnabled = true
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let identifier = segue.identifier {
            switch identifier {
            case "image360Present":
                if let destination = segue.destination as? ViewController {
                    destination.image = sender as! UIImage
                }
            default:
                ()
            }
        }
    }
}
