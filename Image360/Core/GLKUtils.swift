//
//  GLKUtils.swift
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

import GLKit
/// OpenGL Texture unit reference.
typealias GLTextureUnit = GLenum

/// OpenGL Method for error detection
/// - parameter msg: Output character string at detection
func glCheckError(_ msg: String) {
    var error: GLenum = 0
    let noError = GLenum(GL_NO_ERROR)
    repeat{
        error = glGetError()
        if error != noError {
            switch error {
            case GLenum(GL_INVALID_ENUM):
                print("OpenGL error: \(error)(GL_INVALID_ENUM) func: %@\n", error, msg)
            case GLenum(GL_INVALID_VALUE):
                print("OpenGL error: \(error)(GL_INVALID_VALUE) func:%@\n", error, msg)
            case GLenum(GL_INVALID_OPERATION):
                print("OpenGL error: \(error)(GL_INVALID_OPERATION) func:%@\n", error, msg)
            case GLenum(GL_OUT_OF_MEMORY):
                print("OpenGL error: \(error)(GL_OUT_OF_MEMORY) func:%@\n", error, msg)
            default:
                print("OpenGL error: \(error) func:%@", error, msg)
            }
        }
    } while error != noError
}

/// OpenGL Method to load textures to memory.
/// - parameter data: Dictionary with images which should be loaded to textures memory. 
/// Each texture will be associated with uniq key-texture unit.
func glLoadTextures(_ data: [GLTextureUnit : CGImage]) -> [GLTextureUnit : GLKTextureInfo] {
    var result: [GLTextureUnit : GLKTextureInfo] = [:]
    
    for (textureUnit, image) in data {
        do {
            result[textureUnit] = try GLKTextureLoader.texture(with: image, options: nil)
        } catch let error {
            fatalError("texture load failed: \(error.localizedDescription)")
        }
    }
    
    for (textureUnit, textureInfo) in result {
        glActiveTexture(textureUnit)
        glCheckError("glActiveTexture error")
        glBindTexture(GLenum(GL_TEXTURE_2D), textureInfo.name)
        glCheckError("glBindTexture error")
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GLfloat(GL_NEAREST))
        glCheckError("glTexParameterf error")
        glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GLfloat(GL_LINEAR))
        glCheckError("glTexParameterf error")
    }
    
    return result
}

/// OpenGL Method to unload texture from memory.
/// - parameter unit: Texture unit specified for texture.
/// - parameter info: Texture info.
func glUnloadTexture(unit: GLTextureUnit, info: GLKTextureInfo) {
    glActiveTexture(unit)
    glCheckError("glActiveTexture")
    glBindTexture(info.target, 0)
    glCheckError("glBindTexture")
    var textureNames = [info.name]
    glDeleteTextures(1, &textureNames)
    glCheckError("glDeleteTextures")
}

/// OpenGL Method to unload textures from memory.
/// - parameter data: Dictionare of texture info with associated key-texture units.
func glUnloadTextures(_ data: [GLTextureUnit : GLKTextureInfo]) {
    for (textureUnit, textureInfo) in data {
        glUnloadTexture(unit: textureUnit, info: textureInfo)
    }
}

/// Creates & Compiles OpenGL shader.
/// - parameter shaderType: Specifies the type of shader to be created. GL_VERTEX_SHADER or GL_FRAGMENT_SHADER.
/// - parameter source: Shader source code(GLSL).
/// - returns: OpenGL shader's reference.
func glCreateAndCompileShader(shaderType: GLenum, source: String) -> GLuint {
    let nsString = NSString(string: source)
    var shaderStringUTF8: UnsafePointer<GLchar>? = nsString.utf8String
    var shaderStringLength: GLint = GLint(source.utf8.count)
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
/// - returns: OpenGL program's reference.
func glCreateProgram(vertexShaderSrc: String, fragmentShaderSrc: String) -> GLuint {
    // load the vertex shader
    let vertexShader = glCreateAndCompileShader(shaderType: GLenum(GL_VERTEX_SHADER), source: vertexShaderSrc)
    guard vertexShader != 0 else {
        print("glCreateProgram error: vertexShader == 0")
        return 0
    }
    // load fragment shader
    let fragmentShader = glCreateAndCompileShader(shaderType: GLenum(GL_FRAGMENT_SHADER), source: fragmentShaderSrc)
    guard fragmentShader != 0 else {
        glDeleteShader(vertexShader)
        print("glCreateProgram error: fragmentShader == 0")
        return 0
    }
    // create the program object
    let program = glCreateProgram()
    if program == 0 {
        glDeleteShader(vertexShader)
        glDeleteShader(fragmentShader)
        print("glCreateProgram error: program == 0")
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
        print("glCreateProgram error: linked != GL_TRUE")
        return 0
    }
    
    glDeleteShader(vertexShader)
    glDeleteShader(fragmentShader)
    
    return program
}

/// Modifies the value of a matrix uniform variable or a uniform variable array like `glUniformMatrix4fv`.
/// - parameter location: Location of the uniform value to be modified.
/// - parameter transpose: Whether to transpose the matrix as the values are loaded into the uniform variable. Must be GL_FALSE.
/// - parameter matrix: Matrix that will be used to update the specified uniform variable.
func glUniformGLKMatrix4(_ location: GLint, _ transpose: GLboolean, _ matrix: inout GLKMatrix4) {
    let capacity = MemoryLayout.size(ofValue: matrix.m)/MemoryLayout.size(ofValue: matrix.m.0)
    withUnsafePointer(to: &matrix.m) {
        $0.withMemoryRebound(to: GLfloat.self, capacity: capacity) {
            glUniformMatrix4fv(location, 1, transpose, $0)
        }
    }
}
