import MetalKit


struct PositionOffsets {
    let x: Float
    let y: Float
    let z: Float
}

class BoxPrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .triangles,
                           allocator: allocator)
    }
}


class SpherePrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(sphereWithExtent: [size/2,size/2,size/2],
                       segments: [20,20],
                       inwardNormals: false,
                       geometryType: .triangles,
                       allocator: allocator)
    }
}

class ConePrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(coneWithExtent: [size,size,size],
                       segments: [2,20],
                       inwardNormals: false, cap: true,
                       geometryType: .triangles,
                       allocator: allocator)

    }
}

class IcosanhedronPrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(icosahedronWithExtent: [size,size,size],
                       inwardNormals: false,
                       geometryType: .triangles,
                       allocator: allocator)
    }
}

class Primitive {

    var behaviour: ((Float) -> PositionOffsets)?

    let color: NSColor

    let size: Float

    var mesh: MDLMesh!

    var mtkMesh: MTKMesh!

    init?(size: Float, color: NSColor, behaviour: ((Float) -> PositionOffsets)? = nil) {
        self.color = color
        self.size = size
        self.behaviour = behaviour
    }

    /// Override this method to create mesh with provided allocator
    func create(allocator: MTKMeshBufferAllocator) {}

    func generateMTKMesh(device: MTLDevice) {
        mtkMesh = mesh.asMTKMesh(device: device)
    }
}

extension MDLMesh {
    
    func asMTKMesh(device: MTLDevice) -> MTKMesh {
        try! MTKMesh(mesh: self, device: device)
    }
}
