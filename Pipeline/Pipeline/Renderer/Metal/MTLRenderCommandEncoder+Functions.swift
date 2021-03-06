import MetalKit
import Cocoa

struct PositionOffsets {
    let x: Float
    let y: Float
    let z: Float
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

    func draw(mtkMesh: MTKMesh) {
        mtkMesh.submeshes.forEach(draw(mtkSubmesh:))
    }

    func draw(mtkSubmesh: MTKSubmesh) {
        drawIndexedPrimitives(type: mtkSubmesh.primitiveType,
        indexCount: mtkSubmesh.indexCount,
        indexType: mtkSubmesh.indexType,
        indexBuffer: mtkSubmesh.indexBuffer.buffer,
        indexBufferOffset: mtkSubmesh.indexBuffer.offset)
    }
}

fileprivate extension PositionOffsets {

    /// Compatible with `MTLLibrary.vertexAdvancedFunction`
    var fragmentBytes: vector_float3 {
        vector_float3(x,y,z)
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

    /// Compatible with MTKView
    var mtlColor: MTLClearColor {
        MTLClearColor(
            red: Double(redComponent),
            green: Double(greenComponent),
            blue: Double(blueComponent),
            alpha: Double(alphaComponent)
        )
    }

    /// mtlColor field is supported only with RGB colorspace.
    static var rgbBlack: NSColor {
        NSColor(colorSpace: .genericRGB, components: [
            CGFloat(0),
            CGFloat(0),
            CGFloat(0),
            CGFloat(0)
        ], count: 4)
    }
}
