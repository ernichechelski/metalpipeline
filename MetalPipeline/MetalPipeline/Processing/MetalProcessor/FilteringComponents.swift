//
//  FilterConfiguration.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//
//  All required components to make processing.
//

import Metal
import MetalKit
import MetalPerformanceShaders

final class FilteringComponents {

    let view: MTKView
    let commandBuffer: MTLCommandBuffer
    let encoder: MTLComputeCommandEncoder
    let sourceTexture: MTLTexture
    let destinationTexture: MTLTexture

    internal init(encoder: MTLComputeCommandEncoder,
                  view: MTKView,
                  sourceTexture: MTLTexture,
                  destinationTexture: MTLTexture,
                  commandBuffer: MTLCommandBuffer) {
        self.encoder = encoder
        self.view = view
        self.sourceTexture = sourceTexture
        self.destinationTexture = destinationTexture
        self.commandBuffer = commandBuffer
    }
}
