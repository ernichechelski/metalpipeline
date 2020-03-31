//
//  FilterProcessor.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

final class FilterProcessor: NSObject, MTKViewDelegate {

    private var context: GraphicContext
    private var pipelineState: MTLComputePipelineState?
    private var texture: MTLTexture?
    private var filter: MediaFilter
    private var renderTimesCount: Int = 0
    private var processFinished: Bool = false
    private var completionClosure: ((_ success: Bool, _ finished: Bool, _ image: UIImage?, _ error: Error?) -> ())?

    init?(mediaFilter: MediaFilter) {
        filter = mediaFilter
        guard let context = GraphicContext(mediaFilter: filter) else { return nil }
        self.context = context
        super.init()
    }

    func processImage(image: UIImage, completion: @escaping ((_ success: Bool, _ finished: Bool, _ image: UIImage?, _ error: Error?) -> ())) {

        let mtkView = with(MTKView(frame: CGRect.zero)) {
            $0.device = context.device
            $0.delegate = self
            $0.framebufferOnly = false
            $0.autoResizeDrawable = false
            $0.drawableSize = image.size
        }

        completionClosure = completion

        do {
            pipelineState = try context.makePipelineState()
            texture = try context.makeTexture(for: image.cgImage!)

            mtkView.draw()

            for i in 0...renderTimesCount {
                processFinished = i == renderTimesCount
                mtkView.draw()
            }

        } catch {
            completionClosure!(false, false, nil, error)
        }
    }

    func draw(in view: MTKView) {
        context.process { commandBuffer in

            let drawingTexture = view.currentDrawable!.texture

            let encoder = with(commandBuffer.makeComputeCommandEncoder()!) {
                $0.setComputePipelineState(pipelineState!)
                $0.setTexture(texture, index: 0)
                $0.setTexture(drawingTexture, index: 1)
            }

            let configuration = FilterConfiguration(
                                    encoder: encoder,
                                    view: view,
                                    sourceTexture: drawingTexture,
                                    destinationTexture: drawingTexture,
                                    commandBuffer: commandBuffer
                                )

            let threadGroupCount = drawingTexture.recommendedThreadGroupCount
            let threadGroups = drawingTexture.recommendedThreads

            if filter.hasCustomShader {
                filter.manageParameters(configuration: configuration)
                encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                encoder.endEncoding()
            } else {
                encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                encoder.endEncoding()
                filter.manageParameters(configuration: configuration)
            }

            commandBuffer.present(view.currentDrawable!)
        }

        completionClosure!(true, processFinished, UIImage.image(fromTexture: view.currentDrawable!.texture), nil)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderTimesCount += 1
    }
}

fileprivate extension MTLTexture {

    var recommendedThreadGroupCount: MTLSize {
        MTLSizeMake(16, 16, 1)
    }

    var recommendedThreads: MTLSize {
        MTLSizeMake(width / recommendedThreadGroupCount.width, height / recommendedThreadGroupCount.height, 1)
    }
}
