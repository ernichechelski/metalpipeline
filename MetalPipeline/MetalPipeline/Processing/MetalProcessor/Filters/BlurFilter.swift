//
//  BlurFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import MetalPerformanceShaders

final class BlurFilter: Filter {

    override var name: String { "blur_filter" }

    private let sigma: Float = 45

    override func manageParameters(configuration: FilteringComponents) {
        let filter = self
        let blurFilter = MPSImageGaussianBlur(device: configuration.view.device!, sigma: filter.sigma)
        blurFilter.encode(commandBuffer: configuration.commandBuffer, sourceTexture: configuration.sourceTexture, destinationTexture: configuration.destinationTexture)
    }
}
