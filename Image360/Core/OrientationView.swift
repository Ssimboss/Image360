//
//  OrientationView.swift
//  Image360
//
//  Created by Andrew Simvolokov on 26.02.17.
//  Copyright © 2017 Andrew Simvolokov. All rights reserved.
//

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
