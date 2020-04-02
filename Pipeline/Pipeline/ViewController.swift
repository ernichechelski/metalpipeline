import Cocoa
import MetalKit

final class ViewController: NSViewController {

    var renderer: MetalRenderer2?

    var counter = 0

    var primitives = [
        SpherePrimitive(size: 0.9,
                        color: .red,
                        behaviour: { PositionOffsets(x: sin($0), y: sin($0), z: 0) })!,
        BoxPrimitive(size: 0.5,
                     color: .blue,
                     behaviour: { PositionOffsets(x: cos($0), y: cos($0), z: 0) })!,
        IcosanhedronPrimitive(size: 0.3,
                              color: .green,
                              behaviour: { PositionOffsets(x: tan($0), y: tan($0), z: 0) })!,
        ConePrimitive(size: 0.7,
                      color: .yellow,
                      behaviour: { PositionOffsets(x: cos($0), y: sin(-$0), z: 0) })!
    ]
  
    @IBAction func buttonTapped(_ sender: Any) {
        counter += 1
        primitives.shuffle()
        renderer?.setRendering(primitives: primitives)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let metalView = view as? MTKView else {
            fatalError("metal view not set up in storyboard")
        }
        renderer = MetalRenderer2(metalView: metalView)
        metalView.clearColor = NSColor.rgbWhite.mtlColor
    }
}

