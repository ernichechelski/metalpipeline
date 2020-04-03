import MetalKit

final class IcosanhedronPrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(icosahedronWithExtent: [size,size,size],
                       inwardNormals: false,
                       geometryType: .triangles,
                       allocator: allocator)
    }
}
