//
//  OrientationView.swift
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

/// ## OrientationView
/// The `OrientationView` displays current camera position.
internal class OrientationView: UIView {
    private let lineWidth: CGFloat = 3.0
    private let dotSize: CGFloat = 6.0
    
    private var _backgroundColor: UIColor? = nil
    
    override open var backgroundColor: UIColor? {
        set {
            _backgroundColor = newValue
            super.backgroundColor = .clear
        }
        get {
            return _backgroundColor
        }
    }
    
    var orientationAngle: CGFloat = 0
    var fieldOfView: CGFloat = CGFloat.pi / 2
    
    open override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            context.clear(rect)
            context.beginPath()
            if let backgroundColor = _backgroundColor {
                context.setFillColor(backgroundColor.cgColor)
                context.fillEllipse(in: rect)
            }
            
            if let tintColor = tintColor {
                context.setFillColor(tintColor.cgColor)
                context.fillEllipse(in: CGRect(origin: CGPoint(x: rect.midX - dotSize / 2 ,
                                                               y: rect.midY - dotSize / 2),
                                               size: CGSize(width: dotSize, height: dotSize)
                    )
                )
                
                context.setStrokeColor(tintColor.cgColor)
                context.setLineCap(.round)
                context.setLineWidth(lineWidth)
                
                let center = CGPoint(x: rect.midX, y: rect.midY)
                
                context.addArc(center: center,
                               radius: rect.width / 2 - lineWidth,
                               startAngle: orientationAngle - CGFloat.pi / 2 - fieldOfView / 2,
                               endAngle: orientationAngle - CGFloat.pi / 2 + fieldOfView / 2,
                               clockwise: false)
                
                context.addLines(between: [CGPoint(x: center.x - dotSize / 8, y: center.y - dotSize / 4),
                                           CGPoint(x: center.x, y: center.y - dotSize / 2),
                                           CGPoint(x: center.x + dotSize / 8, y: center.y - dotSize / 4),
                    ])
            }
            
            context.strokePath()
        }
    }
}

extension OrientationView: Image360ViewObserver {
    public func image360View(_ view: Image360View, didRotateOverXZ rotationAngleXZ: Float) {
        orientationAngle = CGFloat(rotationAngleXZ)
        self.setNeedsDisplay()
    }
    public func image360View(_ view: Image360View, didRotateOverY rotationAngleY: Float) {
    }
    public func image360View(_ view: Image360View, didChangeFOV cameraFov: Float) {
        fieldOfView = CGFloat(cameraFov / 180 * Float.pi)
        self.setNeedsDisplay()
    }
}
