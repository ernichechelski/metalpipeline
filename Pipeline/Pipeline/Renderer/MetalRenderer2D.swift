import MetalKit
import Cocoa

final class MetalRenderer2D: NSObject, MTKViewDelegate {

    private let metalView: MTKView
    private let library: MTLLibrary
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
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
        self.allocator = MTKMeshBufferAllocator(device: device)
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

            let vertexBuffer = $0.mtkMesh.vertexBuffers.first?.buffer
            vertexBuffer?.setPurgeableState(.nonVolatile)

            let parameters = MTLRenderPassDescriptorParameters(
                vertexFunction: vertexFunction,
                fragmentFunction: fragmentFunction,
                vertexDescriptor: $0.mesh.mtkVertexDescriptor,
                colorPixelFormat: metalView.colorPixelFormat
            )

            let pipelineDescriptor = parameters.mtlRenderPipelineDescriptor
            do {
                let pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)

                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

                renderEncoder.setPositionOffset(offset: $0.behaviour?(timer) ?? PositionOffsets(x: 0, y: 0, z: 0))
                renderEncoder.setColor($0.color)
                renderEncoder.set(mtkMesh: $0.mtkMesh)

            } catch let error {
                fatalError(error.localizedDescription)
            }
            vertexBuffer?.setPurgeableState(.volatile)
        }

        renderEncoder.endEncoding()


        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

