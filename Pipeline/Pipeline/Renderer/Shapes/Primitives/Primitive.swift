import MetalKit

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

fileprivate extension MDLMesh {
    func asMTKMesh(device: MTLDevice) -> MTKMesh {
        try! MTKMesh(mesh: self, device: device)
    }
}
