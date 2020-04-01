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

final class FilterProcessor: NSObject, MTKViewDelegate, ImageProcessor {

    enum ProcessingError: Error {
        case noCGImage
        case emptyRenderedDrawable
        case emptyRenderedTexture
    }

    private var pipelineState: MTLComputePipelineState?
    private var texture: MTLTexture?
    private var renderTimesCount: Int = 0
    private var processFinished: Bool = false
    private var completionClosure: ((_ success: Bool, _ finished: Bool, _ image: UIImage?, _ error: Error?) -> ())?

    private let device: MetalDeviceWrapper

    init?(mediaFilter: Filter) {
        guard let context = MetalDeviceWrapper(mediaFilter: mediaFilter) else { return nil }
        self.device = context
        super.init()
    }

    func processImage(image: UIImage, completion: @escaping ((_ success: Bool, _ finished: Bool, _ image: UIImage?, _ error: Error?) -> ())) {

        let mtkView = with(MTKView(frame: CGRect.zero)) {
            $0.device = device.device
            $0.delegate = self
            $0.framebufferOnly = false
            $0.autoResizeDrawable = false
            $0.drawableSize = image.size
        }

        guard let cgImage = image.cgImage else {
            completionClosure!(false, false, nil, ProcessingError.noCGImage)
            return
        }

        completionClosure = completion

        do {
            pipelineState = try device.makePipelineState()
            texture = try device.makeTexture(for: cgImage)

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
        device.process { commandBuffer in

            let drawingTexture = view.currentDrawable!.texture

            let encoder = with(commandBuffer.makeComputeCommandEncoder()!) {
                $0.setComputePipelineState(pipelineState!)
                $0.setTexture(texture, index: 0)
                $0.setTexture(drawingTexture, index: 1)
            }

            let configuration = FilteringComponents(
                                    encoder: encoder,
                                    view: view,
                                    sourceTexture: drawingTexture,
                                    destinationTexture: drawingTexture,
                                    commandBuffer: commandBuffer
                                )

            let threadGroupCount = drawingTexture.recommendedThreadGroupCount
            let threadGroups = drawingTexture.recommendedThreads

            if device.hasCustomShader {
                device.manageParameters(configuration)
                encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                encoder.endEncoding()
            } else {
                encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
                encoder.endEncoding()
                device.manageParameters(configuration)
            }

            guard let result = view.currentDrawable else {
                completionClosure!(false, false, nil, ProcessingError.emptyRenderedDrawable)
                return
            }

            commandBuffer.present(result)
        }

        guard let resultTexture = view.currentDrawable?.texture else {
            completionClosure!(false, false, nil, ProcessingError.emptyRenderedTexture)
            return
        }

        completionClosure!(true, processFinished, UIImage(fromTexture: resultTexture), nil)
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
        MTLSizeMake(width / recommendedThreadGroupCount.width,
                    height / recommendedThreadGroupCount.height,
                    1)
    }
}
