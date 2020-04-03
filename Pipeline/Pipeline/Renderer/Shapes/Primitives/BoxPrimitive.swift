import MetalKit

final class BoxPrimitive: Primitive {
    
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .triangles,
                           allocator: allocator)
    }
}
