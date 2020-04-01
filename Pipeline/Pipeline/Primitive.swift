import MetalKit


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
        mesh = MDLMesh(sphereWithExtent: [size/2,size/2,size/2], segments: [20,20], inwardNormals: false, geometryType: .triangles, allocator: allocator)
    }

    override func calculateParam(time: Float) -> Float {
        tan(time)
    }
}

class ConePrimitive: Primitive {
    override func create(allocator: MTKMeshBufferAllocator) {
        mesh = MDLMesh(coneWithExtent: [size,size,size], segments: [2,20], inwardNormals: false, cap: true, geometryType: .triangles, allocator: allocator)
    }
}

class Primitive {

    let color: NSColor

    let size: Float

    var mesh: MDLMesh!

    init?(size: Float, color: NSColor) {
        self.color = color
        self.size = size
    }

    /// Override this method to create mesh with provided allocator
    func create(allocator: MTKMeshBufferAllocator) {}

    ///
    func calculateParam(time: Float) -> Float {
        sin(time)
    }
}

extension MDLMesh {
    
    func asMTKMesh(device: MTLDevice) -> MTKMesh {
        try! MTKMesh(mesh: self, device: device)
    }
}
