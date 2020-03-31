//
//  BlurFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

class BlurFilter: MediaFilter {

    override var name: String { "blur_filter" }

    private let kBlurSigmaDefaultValue: Float = 45

    var sigma: Float = 0

    override init() {
        super.init()
        sigma = kBlurSigmaDefaultValue
    }

    override func manageParameters(configuration: FilterConfiguration) {
        let filter = self
        let blurFilter = MPSImageGaussianBlur(device: configuration.view.device!, sigma: filter.sigma)
        blurFilter.encode(commandBuffer: configuration.commandBuffer, sourceTexture: configuration.sourceTexture, destinationTexture: configuration.destinationTexture)
    }
}
