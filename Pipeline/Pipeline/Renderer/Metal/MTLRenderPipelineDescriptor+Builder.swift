import MetalKit

struct MTLRenderPassDescriptorParameters {

    fileprivate let vertexFunction: MTLFunction
    fileprivate let fragmentFunction: MTLFunction
    fileprivate let vertexDescriptor: MTLVertexDescriptor
    fileprivate let colorPixelFormat: MTLPixelFormat

    init(vertexFunction: MTLFunction, fragmentFunction: MTLFunction, vertexDescriptor: MTLVertexDescriptor, colorPixelFormat: MTLPixelFormat) {
        self.vertexFunction = vertexFunction
        self.fragmentFunction = fragmentFunction
        self.vertexDescriptor = vertexDescriptor
        self.colorPixelFormat = colorPixelFormat
    }

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
