import MetalKit
import Cocoa

final class MetalRenderer: NSObject {

    private var metalView: MTKView
    private var commandQueue: MTLCommandQueue
    private var mtkMesh: MTKMesh?
    private var vertexBuffer: MTLBuffer?
    private var pipelineState: MTLRenderPipelineState?
    private var timer: Float = 0
    private var library: MTLLibrary
    private var device: MTLDevice
    private var primitve: Primitive?
    private var allocator: MTKMeshBufferAllocator

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
        self.allocator = MTKMeshBufferAllocator(device: device)
        super.init()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0,
                                             blue: 0.8, alpha: 1)
        metalView.delegate = self
    }

    func setRendering(primitive: Primitive) {
        self.primitve = primitive
        primitve!.create(allocator: allocator)
        mtkMesh = primitve!.mesh.asMTKMesh(device: device)

        vertexBuffer = mtkMesh?.vertexBuffers[0].buffer

        let parameters = MTLRenderPassDescriptorParameters(
            vertexFunction: library.vertexAdvancedFunction,
            fragmentFunction: library.fragmentColorFunction,
            vertexDescriptor: primitve!.mesh.mtkVertexDescriptor,
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

extension MetalRenderer: MTKViewDelegate {

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        timer += 0.02
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
            let pipelineState = pipelineState,
            let mtkMesh = mtkMesh
        else {
            return
        }
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        renderEncoder.setPositionOffset(offset: .init(x:primitve!.calculateParam(time: timer),
                                                      y: primitve!.calculateParam(time: timer),
                                                      z: primitve!.calculateParam(time: timer)))
        renderEncoder.setColor(primitve!.color)
        renderEncoder.set(mtkMesh: mtkMesh)

        renderEncoder.endEncoding()

        guard let drawable = view.currentDrawable else { return }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension MTLLibrary {

    var vertexFunction: MTLFunction {
        makeFunction(name: "vertex_main")!
    }

    var vertexAdvancedFunction: MTLFunction {
        makeFunction(name: "vertex_advanced")!
    }

    var fragmentFunction: MTLFunction {
        makeFunction(name: "fragment_main")!
    }

    var fragmentColorFunction: MTLFunction {
        makeFunction(name: "fragment_color")!
    }
}

struct PositionOffsets {
    let x: Float
    let y: Float
    let z: Float

    var fragmentBytes: vector_float3 {
        vector_float3(x,y,z)
    }
}

extension MTLRenderCommandEncoder {

    /// Compatible with `MTLLibrary.fragmentColorFunction`
    func setColor(_ color: NSColor) {
        var fragmentColor = color.fragmentBytes
        setFragmentBytes(&fragmentColor, length: MemoryLayout.size(ofValue: fragmentColor), index: 0)
    }

    /// Compatible with `MTLLibrary.vertexFunction`
    func setYOffset(offset: Float) {
        var currentOffset = offset
        setVertexBytes(&currentOffset, length: MemoryLayout<Float>.stride, index: 1)
    }

    /// Compatible with `MTLLibrary.vertexAdvancedFunction`
    func setPositionOffset(offset: PositionOffsets) {
        var currentOffset = offset.fragmentBytes
        setVertexBytes(&currentOffset, length: MemoryLayout.size(ofValue: currentOffset), index: 1)
    }

    func set(mtkMesh: MTKMesh) {
        mtkMesh.submeshes.forEach {
            drawIndexedPrimitives(type: .triangle,
                                  indexCount: $0.indexCount,
                                  indexType: $0.indexType,
                                  indexBuffer: $0.indexBuffer.buffer,
                                  indexBufferOffset: $0.indexBuffer.offset)
        }
    }
}

extension NSColor {

    /// Compatible with `fragment_color`
    var fragmentBytes: vector_float4 {
        vector_float4(
            Float(redComponent),
            Float(greenComponent),
            Float(blueComponent),
            Float(alphaComponent)
        )
    }
}
