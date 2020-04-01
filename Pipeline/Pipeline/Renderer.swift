/**
 * Copyright (c) 2018 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MetalKit

final class MetalRenderer: NSObject {

    private var metalView: MTKView
    private var commandQueue: MTLCommandQueue
    private var mtkMesh: MTKMesh?
    private var vertexBuffer: MTLBuffer?
    private var pipelineState: MTLRenderPipelineState?
    private var timer: Float = 0
    private var library: MTLLibrary
    private var device: MTLDevice

    init?(metalView: MTKView) {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue(),
            let library = device.makeDefaultLibrary()
            else {
                fatalError("GPU not available")
        }

        self.device = device
        self.library = library
        self.metalView = metalView
        self.metalView.device = device
        self.commandQueue = commandQueue

        super.init()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1)
        metalView.delegate = self
        setRendering()
    }

    func setRendering() {

        let mdlMesh = BoxPrimitive(device: device, size: 1.0)!
        mtkMesh = mdlMesh.asMTKMesh(device: device)

        vertexBuffer = mtkMesh?.vertexBuffers[0].buffer

        let parameters = MTLRenderPassDescriptorParameters(
            vertexFunction: library.vertexFunction,
            fragmentFunction: library.fragmentFunction,
            vertexDescriptor: mdlMesh.mtkVertexDescriptor,
            colorPixelFormat: metalView.colorPixelFormat
        )

        let pipelineDescriptor = parameters.mtlRenderPipelineDescriptor
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }
}

struct MTLRenderPassDescriptorParameters {
    let vertexFunction: MTLFunction
    let fragmentFunction: MTLFunction
    let vertexDescriptor: MTLVertexDescriptor
    let colorPixelFormat: MTLPixelFormat

    var mtlRenderPipelineDescriptor: MTLRenderPipelineDescriptor {
        MTLRenderPipelineDescriptor.from(self)
    }
}

extension MDLMesh {
    var mtkVertexDescriptor: MTLVertexDescriptor {
        MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)!
    }
}

extension MTLRenderPipelineDescriptor {

    static func from(_ parameters: MTLRenderPassDescriptorParameters) -> MTLRenderPipelineDescriptor {
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = parameters.vertexFunction
        pipelineDescriptor.fragmentFunction = parameters.fragmentFunction
        pipelineDescriptor.vertexDescriptor = parameters.vertexDescriptor
        pipelineDescriptor.colorAttachments[0].pixelFormat = parameters.colorPixelFormat
        return pipelineDescriptor
    }
}


extension MTLLibrary {
    var vertexFunction: MTLFunction {
        makeFunction(name: "vertex_main")!
    }

    var fragmentFunction: MTLFunction {
        makeFunction(name: "fragment_main")!
    }

    var fragmentColorFunction: MTLFunction {
        makeFunction(name: "fragment_color")!
    }
}

extension MetalRenderer: MTKViewDelegate {
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

  func draw(in view: MTKView) {
    guard
        let descriptor = view.currentRenderPassDescriptor,
        let commandBuffer = commandQueue.makeCommandBuffer(),
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
        let pipelineState = pipelineState,
        let mtkMesh = mtkMesh
    else {
        return
    }

    timer += 0.02
    var currentTime: Float = sin(timer)
    renderEncoder.setVertexBytes(&currentTime, length: MemoryLayout<Float>.stride, index: 1)

    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
    renderEncoder.encode(mtkMesh: mtkMesh)
    renderEncoder.endEncoding()

    guard let drawable = view.currentDrawable else { return }

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

extension MTLRenderCommandEncoder {
    func encode(mtkMesh: MTKMesh) {
        mtkMesh.submeshes.forEach {
            drawIndexedPrimitives(type: .triangle,
                                  indexCount: $0.indexCount,
                                  indexType: $0.indexType,
                                  indexBuffer: $0.indexBuffer.buffer,
                                  indexBufferOffset: $0.indexBuffer.offset)
        }
    }
}
