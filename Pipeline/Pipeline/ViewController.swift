import Cocoa
import MetalKit

final class ViewController: NSViewController {

    @IBAction private func buttonTapped(_ sender: Any) {
        counter += 1
        primitives.shuffle()
        renderer?.setRendering(primitives: primitives.compactMap { $0 })
    }

    private var metalView: MTKView { view as! MTKView }

    private var counter = 0

    private var primitives = [
        SpherePrimitive(size: 0.9,
                        color: .red,
                        behaviour: { .init(x: sin($0), y: sin($0), z: 0) }),
        BoxPrimitive(size: 0.2,
                     color: .blue,
                     behaviour: { .init(x: cos($0), y: cos($0), z: 0) }),
        BoxPrimitive(size: 0.1,
                     color: .orange,
                     behaviour: { .init(x: cos(-$0), y: cos($0), z: 0) }),
        BoxPrimitive(size: 0.1,
                     color: .brown,
                     behaviour: { .init(x: cos($0), y: cos(-$0), z: 0) }),
        BoxPrimitive(size: 0.1,
                     color: .blue,
                     behaviour: { .init(x: tan(-$0), y: cos(-$0), z: 0) }),
        BoxPrimitive(size: 0.1,
                     color: .magenta,
                     behaviour: { .init(x: sin($0), y: sin($0), z: 0) }),
        BoxPrimitive(size: 0.5,
                     color: .blue,
                     behaviour: { .init(x: cos($0), y: cos($0), z: 0) }),
        IcosanhedronPrimitive(size: 0.3,
                              color: .green,
                              behaviour: { .init(x: tan($0), y: tan($0), z: 0) }),
        ConePrimitive(size: 0.7,
                      color: .yellow,
                      behaviour: { .init(x: cos($0), y: sin(-$0), z: 0) })
    ]

    private var renderer: MetalRenderer2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        renderer = MetalRenderer2D(metalView: metalView)
        metalView.clearColor = NSColor.rgbBlack.mtlColor
    }
}
