//
//  GraphicContext.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

final class MetalDeviceWrapper {

    var hasCustomShader: Bool {
        mediaFilter.hasCustomShader
    }

    let device: MTLDevice

    private let library: MTLLibrary
    private let commandQueue: MTLCommandQueue
    private let textureLoader: MTKTextureLoader
    private let mediaFilter: Filter

    init?(mediaFilter: Filter) {

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let queue = device.makeCommandQueue(),
            let library = try? device.makeLibrary(source: mediaFilter.source!, options: nil)
        else {
            return nil
        }

        self.device = device
        self.library = library
        self.commandQueue = queue
        self.textureLoader = MTKTextureLoader(device: device)
        self.mediaFilter = mediaFilter
    }

    func process(with closure: (MTLCommandBuffer) -> Void) {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
        closure(commandBuffer)
        commandBuffer.commit()
    }

    func makePipelineState() throws -> MTLComputePipelineState? {
        try device.makeComputePipelineState(function: library.makeFunction(name: mediaFilter.name)!)
    }

    func makeTexture(for cgImage: CGImage) throws -> MTLTexture  {
        try MTKTextureLoader(device: device)
        .newTexture(cgImage: cgImage,
                    options: [MTKTextureLoader.Option.SRGB: false])
    }

    func manageParameters(_ configuration: FilteringComponents) {
        mediaFilter.manageParameters(configuration: configuration)
    }
}
