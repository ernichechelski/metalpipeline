import MetalKit

class SpherePrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(sphereWithExtent: [size/2,size/2,size/2],
                       segments: [20,20],
                       inwardNormals: false,
                       geometryType: .triangles,
                       allocator: allocator)
    }
}
