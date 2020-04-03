import MetalKit

final class ConePrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(coneWithExtent: [size,size,size],
                       segments: [2,20],
                       inwardNormals: false, cap: true,
                       geometryType: .lines,
                       allocator: allocator)

    }
}

