import MetalKit
import Cocoa

final class MetalRenderer: NSObject, MTKViewDelegate {

    private let metalView: MTKView
    private let library: MTLLibrary
    private let device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private let allocator: MTKMeshBufferAllocator

    private let vertexFunction: MTLFunction
    private let fragmentFunction: MTLFunction

    private var timer: Float = 0

    private var primitve: Primitive?
    private var pipelineState: MTLRenderPipelineState?
    private var mtkMesh: MTKMesh?
    private var vertexBuffer: MTLBuffer?



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
        self.vertexFunction = library.vertexAdvancedFunction
        self.fragmentFunction = library.fragmentFunction

        self.metalView = metalView
        self.metalView.device = device
        self.commandQueue = commandQueue
        self.allocator = MTKMeshBufferAllocator(device: device)

        super.init()
        
        metalView.delegate = self
    }

    func setRendering(primitive: Primitive) {
        self.primitve = primitive
        primitve!.create(allocator: allocator)
        mtkMesh = primitve!.mesh.asMTKMesh(device: device)

        vertexBuffer = mtkMesh?.vertexBuffers[0].buffer

        let parameters = MTLRenderPassDescriptorParameters(
            vertexFunction: vertexFunction,
            fragmentFunction: fragmentFunction,
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

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        timer += 0.02
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }

        if let pipelineState = pipelineState {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

            renderEncoder.setPositionOffset(offset: primitve!.behaviour?(timer) ?? PositionOffsets(x: 0, y: 0, z: 0))
            renderEncoder.setColor(primitve!.color)
            if let mesh = mtkMesh {
                renderEncoder.set(mtkMesh: mesh)
            }
        }

        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

final class MetalRenderer2: NSObject, MTKViewDelegate {

    private let metalView: MTKView
    private let library: MTLLibrary
    private let device: MTLDevice
    private var commandQueue: MTLCommandQueue
    private let allocator: MTKMeshBufferAllocator

    private let vertexFunction: MTLFunction
    private let fragmentFunction: MTLFunction

    private var timer: Float = 0

    private var primitves = [Primitive]()


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
        allocator = MTKMeshBufferAllocator(device: device)
        self.vertexFunction = library.vertexAdvancedFunction
        self.fragmentFunction = library.fragmentColorFunction
        super.init()
        metalView.delegate = self
    }

    func setRendering(primitives: [Primitive]) {
        self.primitves = primitives
        primitives.forEach {
            $0.create(allocator: allocator)
            $0.generateMTKMesh(device: device)
            print($0.mtkMesh.vertexBuffers.count)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }

    func draw(in view: MTKView) {
        timer += 0.02
        timer = timer.truncatingRemainder(dividingBy: 1000)

        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else {
            return
        }


        primitves.forEach {

            var vertexBuffer = $0.mtkMesh.vertexBuffers.first?.buffer

            let parameters = MTLRenderPassDescriptorParameters(
                vertexFunction: vertexFunction,
                fragmentFunction: fragmentFunction,
                vertexDescriptor: $0.mesh.mtkVertexDescriptor,
                colorPixelFormat: metalView.colorPixelFormat
            )

            let pipelineDescriptor = parameters.mtlRenderPipelineDescriptor
            do {
                let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

//                vertexBuffer.setPurgeableState(.nonVolatile)
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                renderEncoder.setPositionOffset(offset: $0.behaviour?(timer) ?? PositionOffsets(x: 0, y: 0, z: 0))
                renderEncoder.setColor($0.color)
                renderEncoder.set(mtkMesh: $0.mtkMesh)
//                vertexBuffer.setPurgeableState(.volatile)
            } catch let error {
                fatalError(error.localizedDescription)
            }

            vertexBuffer = nil
        }

        renderEncoder.endEncoding()


        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        primitves.map { $0.mtkMesh.vertexBuffers }.compactMap { $0 }.forEach { $0.forEach { $0.buffer.setPurgeableState(.volatile) }  }

        print(commandQueue.device.currentAllocatedSize)
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



fileprivate extension PositionOffsets {
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

    var mtlColor: MTLClearColor {
        MTLClearColor(
            red: Double(redComponent),
            green: Double(greenComponent),
            blue: Double(blueComponent),
            alpha: Double(alphaComponent)
        )
    }


    /// mtlColor field is supported only with RGB colorspace.
    static var rgbWhite: NSColor {
        NSColor(colorSpace: .genericRGB, components: [
            CGFloat(0),
            CGFloat(0),
            CGFloat(0),
            CGFloat(0)
        ], count: 4)
    }
}
