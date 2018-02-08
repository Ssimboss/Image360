//
//  Image360GLController.swift
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
import GLKit

/// ## Image360GLController
/// This controller presentes a special OpenGL view to dysplay 360° panoramic image.
class Image360GLController: GLKViewController {
    /// Image 360 view which actually dysplays 360° panoramic image.
    var imageView: Image360View {
        set {
            self.view = newValue
        }
        get {
            guard let image360View = self.view as? Image360View else {
                fatalError("View of Image360GLController is not a Image360View")
            }
            return image360View
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Image360GLController init?(coder:) isn't implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        self.imageView = Image360View(frame: CGRect(x: 0, y: 0, width: 512, height: 512))
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        imageView.draw(rect)
    }
}
