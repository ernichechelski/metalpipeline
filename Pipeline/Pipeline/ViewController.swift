import Cocoa
import MetalKit

final class ViewController: NSViewController {

    var renderer: MetalRenderer?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        renderer = MetalRenderer(metalView: metalView)
        renderer?.setRendering(primitive: SpherePrimitive(size: 1.0, color: .purple)!)
    }
}

