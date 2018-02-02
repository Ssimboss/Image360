//
//  Image360View.swift
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

protocol Image360ViewTouchesHandler: class {
    func image360View(_ view: Image360View, touchesBegan touches: Set<UITouch>, with event: UIEvent?)
    func image360View(_ view: Image360View, touchesMoved touches: Set<UITouch>, with event: UIEvent?)
    func image360View(_ view: Image360View, touchesEnded touches: Set<UITouch>, with event: UIEvent?)
}

/// ## Image360ViewObserver
/// The `Image360ViewObserver` protocol defines methods that you use to manage
/// reactions to changes of basic fields of `Image360View`.
public protocol Image360ViewObserver: class {
    /// Sent when new value of `rotationAngleXZ` was set.
    func image360View(_ view: Image360View, didRotateOverXZ rotationAngleXZ: Float)
    /// Sent when new value of `rotationAngleY` was set.
    func image360View(_ view: Image360View, didRotateOverY rotationAngleY: Float)
    /// Sent when new value of `cameraFovDegree` was set.
    func image360View(_ view: Image360View, didChangeFOV cameraFov: Float)
}

/// ## Image360View
/// This view presentes a special view to dysplay 360° panoramic image.
/// 
/// You could change current dysplayed image via `image` property.
/// Control view utput via `rotationAngleXZ`, `rotationAngleY` and `cameraFovDegree` properties.
public class Image360View: GLKView {
    // MARK: Sphere data
    private var spheres = [Sphere?].init(repeating: nil, count: 2)

    /// Spherical radius for photo attachment
    private let shellRadius: GLfloat = 2.0
    /// Number of spherical polygon partitions for photo attachment
    private let shellDivide: Int = 48

    // MARK: Principal axes
    private var roll: Float = 0.0
    private var yaw: Float = 0.0
    private var pitch: Float = 0.0

    private var viewAspectRatio: CGFloat!

    // MARK: Matrixes
    private var projectionMatrix = GLKMatrix4Identity
    private var lookAtMatrix = GLKMatrix4Identity
    private var modelMatrix = GLKMatrix4Identity

    // Shader
    private var shaderProgram: GLuint!
    private var aPosition: GLuint!
    private var aUV: GLuint!
    private var uProjection: GLint!
    private var uView: GLint!
    private var uModel: GLint!
    private var uTex: GLint!

    private var textureInfo: [GLenum: GLKTextureInfo]!

    // MARK: Camera
    private let cameraPosition = GLKVector3(v: (0.0, 0.0, 0.0))
    private let cameraUp = GLKVector3(v: (0.0, 1.0, 0.0))

    /// Camera "Field Of View". Degrees. Readonly.
    /// Use `setCameraFovDegree(newValue:)` to change this value.
    public private(set) var cameraFovDegree: Float = 45.0 {
        didSet {
            observer?.image360View(self, didChangeFOV: cameraFovDegree)
            orientationView?.image360View(self, didChangeFOV: cameraFovDegree)
        }
    }
    /// Sets new value to `cameraFovDegree`
    /// - parameter newValue: New value of `cameraFovDegree` to be set.
    /// Could be ignored/changed in case it's out of range 30 .. 100
    public func setCameraFovDegree(newValue: Float) {
        if newValue > cameraFOVDegreeMax {
            cameraFovDegree = cameraFOVDegreeMax
        } else if newValue < cameraFOVDegreeMin {
            cameraFovDegree = cameraFOVDegreeMin
        } else {
            cameraFovDegree = newValue
        }
    }
    /// Deafult(init) value of `cameraFovDegree`
    public let cameraFovDegreeDefault: Float = 45.0
    /// Minimum possible value of `cameraFovDegree`
    public let cameraFOVDegreeMin: Float = 30.0
    /// Maximum possible value of `cameraFovDegree`
    public let cameraFOVDegreeMax: Float = 100.0

    private let zNear: Float = 0.1
    private let zFar: Float = 100.0

    // MARK: Rotation
    /// Rotation angle relative to XZ-plane. Radians. Readonly.
    /// Use `setRotationAngleXZ(newValue:)` to change this value.
    public private(set) var rotationAngleXZ: Float = 0.0 {
        didSet {
            observer?.image360View(self, didRotateOverXZ: rotationAngleXZ)
            orientationView?.image360View(self, didRotateOverXZ: rotationAngleXZ)
        }
    }
    /// Sets new value to `rotationAngleXZ`
    /// - parameter newValue: New value of `rotationAngleXZ` to be set.
    /// Could be ignored/changed in case it's out of range -π .. π
    public func setRotationAngleXZ(newValue: Float) {
        if newValue > rotationAngleXZMax {
            rotationAngleXZ = fmod(newValue, 2 * Float.pi) - 2 * Float.pi
        } else if newValue < rotationAngleXZMin {
            rotationAngleXZ = fmod(newValue, 2 * Float.pi) + 2 * Float.pi
        } else {
            rotationAngleXZ = newValue
        }
    }
    /// Minimum possible value of `rotationAngleXZ`
    public let rotationAngleXZMax = Float.pi
    /// Maximum possible value of `rotationAngleXZ`
    public let rotationAngleXZMin = -Float.pi

    /// Rotation angle relative to Y-axis. Radians. Readonly.
    /// Use `setRotationAngleY(newValue:)` to change this value.
    public private(set) var rotationAngleY: Float = 0.0 {
        didSet {
            observer?.image360View(self, didRotateOverY: rotationAngleY)
            orientationView?.image360View(self, didRotateOverY: rotationAngleY)
        }
    }
    /// Sets new value to `rotationAngleY`
    /// - parameter newValue: New value of `rotationAngleY` to be set.
    /// Could be ignored/changed in case it's out of range -π/2 .. π/2
    public func setRotationAngleY(newValue: Float) {
        if newValue > rotationAngleYMax {
            rotationAngleY = rotationAngleYMax
        } else if newValue < rotationAngleYMin {
            rotationAngleY = rotationAngleYMin
        } else {
            rotationAngleY = newValue
        }
    }
    /// Minimum possible value of `rotationAngleY`
    public let rotationAngleYMax = Float.pi / 2 - 0.01 //0.01 to prevent screen drag
    /// Maximum possible value of `rotationAngleY`
    public let rotationAngleYMin = -Float.pi / 2 + 0.01 //0.01 to prevent screen drag

    weak var touchesHandler: Image360ViewTouchesHandler?
    public weak var observer: Image360ViewObserver?
    
    weak var orientationView: OrientationView?

    /// OpenGL Sources
    private let leftTextureUnit = GLenum(GL_TEXTURE0)
    private let rightTextureUnit = GLenum(GL_TEXTURE1)
    
    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        guard let context = EAGLContext(api: .openGLES3) else {
            fatalError("OpenGL context can't be created")
        }

        EAGLContext.setCurrent(context)
        self.context = context

        self.initOpenGLSettings()

        spheres[0] = Sphere(radius: shellRadius, divide: shellDivide, rotate: 0.0)
        spheres[1] = Sphere(radius: shellRadius, divide: shellDivide, rotate: Double.pi)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // TODO:!
    }

    deinit {
        unloadTextures()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        viewAspectRatio = frame.size.width / frame.size.height
    }

    /// OpenGL Initial value setting method
    /// - parameter context: OpenGL Context
    private func initOpenGLSettings() {
        let viewWidth = frame.size.width
        let viewHeight = frame.size.height

        shaderProgram = glCreateProgram(vertexShaderSrc: Shader.vertexShader.sourceCode,
                                        fragmentShaderSrc: Shader.fragmentShader.sourceCode)
        useAndAttachLocation(program: shaderProgram)

        glClearColor(0.0, 0.0, 1.0, 0.0)

        viewAspectRatio = viewWidth / viewHeight
        glViewport(0, 0, GLsizei(viewWidth), GLsizei(viewHeight))
    }

    private var textureWasSet = false

    /// Image presented in view at the moment. Image need to be captured by special
    /// 360° panoramic camera or generated by special software.
    var image: UIImage? {
        willSet {
            if textureWasSet {
                unloadTextures()
            }
        }

        didSet {
            guard let image = image else {
                return // TODO: what if new image is nil?
            }

            let srcImageRef = image.cgImage

            // Create CGRect specifying clipping position
            let leftArea = CGRect(x: 0, y: 0, width: image.size.width / 2, height: image.size.height)
            let rightArea = CGRect(x: image.size.width / 2.0, y: 0.0, width: image.size.width / 2, height: image.size.height)

            // Create clipped image using CoreGraphics function.
            guard let leftImageRef = srcImageRef!.cropping(to: leftArea) else { // TODO: unwrap?
                fatalError("leftImageRef is nil")
            }

            guard let rightImageRef = srcImageRef!.cropping(to: rightArea) else {
                fatalError("rightImageRef is nil")
            }

            EAGLContext.setCurrent(self.context)
            
            textureInfo = glLoadTextures([leftTextureUnit : leftImageRef,
                                          rightTextureUnit : rightImageRef])

            self.yaw = 0.0 // Do we really need it here?
            self.roll = 0.0
            self.pitch = 0.0

            textureWasSet = true
        }
    }

    /// Redraw method.
    public override func draw(_ rect: CGRect) {
        EAGLContext.setCurrent(self.context)
        
        projectionMatrix = GLKMatrix4Identity
        lookAtMatrix = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Identity

        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))

        let cameraDirection = GLKVector3(v: (cos(rotationAngleXZ) * cos(rotationAngleY),
                                             sin(rotationAngleY),
                                             sin(rotationAngleXZ) * cos(rotationAngleY)))

        projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(cameraFovDegree),
                                                     Float(viewAspectRatio),
                                                     zNear,
                                                     zFar)
        lookAtMatrix = GLKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
                                            cameraDirection.x, cameraDirection.y, cameraDirection.z,
                                            cameraUp.x, cameraUp.y, cameraUp.z)

        let elevetionAngleMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(pitch), 0, 0, 1)
        modelMatrix = GLKMatrix4Multiply(modelMatrix, elevetionAngleMatrix)
        let horizontalAngleMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(roll), 1, 0, 0)
        modelMatrix = GLKMatrix4Multiply(modelMatrix, horizontalAngleMatrix)

        glEnableVertexAttribArray(aPosition)
        glEnableVertexAttribArray(aUV)

        glUniformGLKMatrix4(uModel, GLboolean(GL_FALSE), &modelMatrix)
        glCheckError("glUniform4fv model")
        glUniformGLKMatrix4(uView, GLboolean(GL_FALSE), &lookAtMatrix)
        glCheckError("glUniform4fv viewmatrix")
        glUniformGLKMatrix4(uProjection, GLboolean(GL_FALSE), &projectionMatrix)
        glCheckError("glUniform4fv projectionmatrix")

        for (index, sphere) in spheres.enumerated() {
            let textureUnit: GLenum = (index == 0) ? leftTextureUnit : rightTextureUnit
            glUniform1i(uTex, GLint(textureUnit - GLenum(GL_TEXTURE0)))
            glCheckError("glUniform1i")
            if let sphere = sphere {
                draw(sphere: sphere, position: aPosition, uvLocation: aUV)
            }
        }

        glDisableVertexAttribArray(aPosition)
        glDisableVertexAttribArray(aUV)
    }

    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesHandler?.image360View(self, touchesBegan: touches, with: event)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesHandler?.image360View(self, touchesMoved: touches, with: event)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesHandler?.image360View(self, touchesEnded: touches, with: event)
    }

    /// Program validation and various shader variable validation methods for OpenGL
    /// - parameter program: OpenGL Program variable
    func useAndAttachLocation(program: GLuint) {
        glUseProgram(program)
        glCheckError("glUseProgram")

        aPosition = GLuint(glGetAttribLocation(program, "aPosition"))
        glCheckError("glGetAttribLocation position")
        aUV = GLuint(glGetAttribLocation(program, "aUV"))
        glCheckError("glGetAttribLocation uv")

        uProjection = glGetUniformLocation(program, "uProjection")
        glCheckError("glGetUniformLocation projection")
        uView = glGetUniformLocation(program, "uView")
        glCheckError("glGetUniformLocation view")
        uModel = glGetUniformLocation(program, "uModel")
        glCheckError("glGetUniformLocation model")
        uTex = glGetUniformLocation(program, "uTex")
        glCheckError("glGetUniformLocation texture")
    }

    func unloadTextures() {
        EAGLContext.setCurrent(self.context)
        glUnloadTextures(textureInfo)
    }

    // MARK: Sphere
    /// Method for drawing spheres
    /// Variables connected to the shader are used for drawing.
    /// It is assumed that shader variables are activated.
    /// - parameter sphere: Sphere object to be drawn.
    /// - parameter position: Attribute compatibility variable for shader connected to the position.
    /// - parameter uvLocation: Attribute compatibility variable for shader connected to the UV space.
    private func draw(sphere: Sphere, position: GLuint, uvLocation: GLuint) {
        for index in 0 ..< sphere.mDivide / 2 {
            glVertexAttribPointer(position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, sphere.vertexArray[index])
            glVertexAttribPointer(uvLocation, 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, sphere.texCoordsArray[index])

            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, GLsizei(sphere.mDivide) + 2)
        }
    }
}
