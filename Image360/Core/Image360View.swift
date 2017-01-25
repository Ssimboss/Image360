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
    private let shellRadius: Float = 2.0
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

    private var textureInfo: [Int32: GLKTextureInfo]!

    // MARK: Camera
    private let cameraPosition = GLKVector3(v: (0.0, 0.0, 0.0))
    private let cameraUp = GLKVector3(v: (0.0, 1.0, 0.0))

    /// Camera "Field Of View". Degrees. Readonly.
    /// Use `setCameraFovDegree(newValue:)` to change this value.
    public private(set) var cameraFovDegree: Float = 45.0 {
        didSet {
            observer?.image360View(self, didChangeFOV: cameraFovDegree)
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
        }
    }
    /// Sets new value to `rotationAngleXZ`
    /// - parameter newValue: New value of `rotationAngleXZ` to be set.
    /// Could be ignored/changed in case it's out of range -π .. π
    public func setRotationAngleXZ(newValue: Float) {
        if newValue > rotationAngleXZMax {
            rotationAngleXZ = fmod(newValue, 2 * Float(M_PI)) - 2 * Float(M_PI)
        } else if newValue < rotationAngleXZMin {
            rotationAngleXZ = fmod(newValue, 2 * Float(M_PI)) + 2 * Float(M_PI)
        } else {
            rotationAngleXZ = newValue
        }
    }
    /// Minimum possible value of `rotationAngleXZ`
    public let rotationAngleXZMax = Float(M_PI)
    /// Maximum possible value of `rotationAngleXZ`
    public let rotationAngleXZMin = -Float(M_PI)

    /// Rotation angle relative to Y-axis. Radians. Readonly.
    /// Use `setRotationAngleY(newValue:)` to change this value.
    public private(set) var rotationAngleY: Float = 0.0 {
        didSet {
            observer?.image360View(self, didRotateOverY: rotationAngleY)
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
    public let rotationAngleYMax = Float(M_PI_2)
    /// Maximum possible value of `rotationAngleY`
    public let rotationAngleYMin = -Float(M_PI_2)

    weak var touchesHandler: Image360ViewTouchesHandler?
    public weak var observer: Image360ViewObserver?

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)

        guard let context = EAGLContext(api: .openGLES2) else { // TODO: version 3 ?
            fatalError("OpenGL context can't be created")
        }

        EAGLContext.setCurrent(context)
        self.context = context

        self.initOpenGLSettings()

        spheres[0] = Sphere(radius: shellRadius, divide: shellDivide, rotate: 0.0)
        spheres[1] = Sphere(radius: shellRadius, divide: shellDivide, rotate: M_PI)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented") // TODO:!
    }

    deinit {
        unloadTextures()
    }

    /// OpenGL Initial value setting method
    /// - parameter context: OpenGL Context
    private func initOpenGLSettings() {
        let viewWidth = frame.size.width
        let viewHeight = frame.size.height

        shaderProgram = loadProgram(vertexShaderSrc: Shader.vertexShader.sourceCode,
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

            let leftTexture: GLKTextureInfo
            do {
                leftTexture = try GLKTextureLoader.texture(with: leftImageRef, options: nil)
            } catch  {
                fatalError("leftTexture generation failed")
            }

            let rightTexture: GLKTextureInfo
            do {
                rightTexture = try GLKTextureLoader.texture(with: rightImageRef, options: nil)
            } catch {
                fatalError("rightTexture generation failed")
            }

            textureInfo = [
                GL_TEXTURE0 : leftTexture,
                GL_TEXTURE1 : rightTexture
            ]

            for (key, value) in textureInfo {
                glActiveTexture(GLenum(key))
                glBindTexture(GLenum(GL_TEXTURE_2D), value.name)

                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GL_NEAREST))
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GL_LINEAR))
            }

            self.yaw = 0.0 // Do we really need it here?
            self.roll = 0.0
            self.pitch = 0.0

            textureWasSet = true
        }
    }

    /// Redraw method.
    func draw() {
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

        glUniformMatrix4fv(uModel, 1, GLboolean(GL_FALSE), &modelMatrix.m.0)
        glCheckError("glUniform4fv model")
        glUniformMatrix4fv(uView, 1, GLboolean(GL_FALSE), &lookAtMatrix.m.0)
        glCheckError("glUniform4fv viewmatrix")
        glUniformMatrix4fv(uProjection, 1, GLboolean(GL_FALSE), &projectionMatrix.m.0)
        glCheckError("glUniform4fv projectionmatrix")

        for (index, sphere) in spheres.enumerated() {
            glUniform1i(uTex, GLint(index))
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

    /// Creates OpenGL shader.
    /// - parameter shaderType: Specifies the type of shader to be created. GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
    /// - parameter source: Shader source code(GLSL).
    private func createShader(shaderType: GLenum, source: String) -> GLuint {
        let nsString = NSString(string: source)
        var shaderStringUTF8: UnsafePointer<GLchar>? = nsString.utf8String
        var shaderStringLength: GLint = GLint(Int32(source.utf8.count))
        var compiled: GLint = 0

        let shader = glCreateShader(shaderType) // Creates shader
        guard shader != 0 else {
            return 0
        }

        glShaderSource(shader, 1, &shaderStringUTF8, &shaderStringLength) // Replaces shader's source code
        glCompileShader(shader) // Compiles shader's code
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compiled) // Puts compile status to compiled

        guard compiled == GL_TRUE else {
            var infoLen: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &infoLen)

            if infoLen > 1 {
                var infoBuffer = [Int8](repeating: 0, count: Int(infoLen))
                var realLength: GLsizei = 0
                glGetShaderInfoLog(shader, GLsizei(infoLen), &realLength, &infoBuffer)
                let errorDescription = String(cString: &infoBuffer)
                print("Shader compile error: \(errorDescription)")
            }

            glDeleteShader(shader) // Delete created shader
            return 0
        }
        return shader
    }

    /// Program creation function for OpenGL
    /// - parameter vertexShaderSrc: Vertex shader source
    /// - parameter fragmentShaderSrc: Fragment shader source
    private func loadProgram(vertexShaderSrc: String, fragmentShaderSrc: String) -> GLuint {
        // load the vertex shader
        let vertexShader = createShader(shaderType: GLenum(GL_VERTEX_SHADER), source: vertexShaderSrc)
        guard vertexShader != 0 else {
            return 0
        }
        // load fragment shader
        let fragmentShader = createShader(shaderType: GLenum(GL_FRAGMENT_SHADER), source: fragmentShaderSrc)
        guard fragmentShader != 0 else {
            glDeleteShader(vertexShader)
            return 0
        }
        // create the program object
        let program = glCreateProgram()
        if program == 0 {
            glDeleteShader(vertexShader)
            glDeleteShader(fragmentShader)
            return 0
        }

        glAttachShader(program, vertexShader)
        glAttachShader(program, fragmentShader)

        // link the program
        glLinkProgram(program)

        // check the link status
        var linked: GLint = 0
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linked)

        guard linked == GL_TRUE else {
            var infoLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &infoLength)

            if infoLength > 1 {
                var infoBuffer = [Int8](repeating: 0, count: Int(infoLength))
                var realLength: GLsizei = 0
                glGetProgramInfoLog(program, GLsizei(infoLength), &realLength, &infoBuffer)
                let errorDescription = String(cString: &infoBuffer)
                print("Linking program error: \(errorDescription)")
            }
            glDeleteProgram(program)
            return 0
        }

        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)

        return program
    }

    /// Program validation and various shader variable validation methods for OpenGL
    /// - parameter program: OpenGL Program variable
    func useAndAttachLocation(program: GLuint) {
        glUseProgram(program)
        glCheckError("glUseProgram")

        aPosition = GLuint(glGetAttribLocation(program, "aPosition"))//TODO: check pointers
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

    /// OpenGL Method for error detection
    /// - parameter msg: Output character string at detection
    func glCheckError(_ msg: String) {
        var error: GLenum = 0
        let noError = GLenum(GL_NO_ERROR)
        repeat{
            error = glGetError()
            if error != noError{
                NSLog("GLERR: \(error) %@¥n", error, msg)
            }
        } while error != noError
    }

    func unloadTextures() {
        if let leftTexture  = textureInfo[GL_TEXTURE0]{
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(leftTexture.target, 0)
            var textures = [leftTexture.name]
            glDeleteTextures(1, &textures)
        }

        if let rightTexture  = textureInfo[GL_TEXTURE1]{
            glActiveTexture(GLenum(GL_TEXTURE1))
            glBindTexture(rightTexture.target, 0)
            var textures = [rightTexture.name]
            glDeleteTextures(1, &textures)
        }
        //context = nil
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

            glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, sphere.mDivide + 2)
        }
    }
}
