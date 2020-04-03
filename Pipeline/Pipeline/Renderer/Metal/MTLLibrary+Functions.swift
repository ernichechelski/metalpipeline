import MetalKit

extension MTLLibrary {

    var vertexFunction: MTLFunction {
        makeFunction(name: "vertex_main")!
    }

    var vertexAdvancedFunction: MTLFunction {
        makeFunction(name: "vertex_advanced")!
    }

    var fragmentFunction: MTLFunction {
        makeFunction(name: "fragment_main")!
    }

    var fragmentColorFunction: MTLFunction {
        makeFunction(name: "fragment_color")!
    }
}
