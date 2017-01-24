//
//  Shader.swift
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

import Foundation

class Shader {
    let sourceCode: String

    init?(filename: String) {
        let components = filename.components(separatedBy: ".")
        guard components.count == 2 else {
            return nil
        }
        guard let url = Bundle(for: Shader.self).url(forResource: components[0],
                                                     withExtension: components[1]) else {
                                                        return nil
        }
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        guard let sourceCode = String(data: data, encoding: String.Encoding.utf8) else {
            return nil
        }
        self.sourceCode = sourceCode
    }

    static let vertexShader = Shader(filename: "VertexShader.glsl")!
    static let fragmentShader = Shader(filename: "FragmentShader.glsl")!
}
