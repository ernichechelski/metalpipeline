//
//  ThresholdFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

class ThresholdFilter: MediaFilter {

    override var name: String { "threshold_filter" }

    private let thresholdValue: Float = 0.5

    override func manageParameters(configuration: FilterConfiguration) {
        let filter = self
        let thresholdFilter = MPSImageThresholdToZero(device: configuration.view.device!, thresholdValue: filter.thresholdValue, linearGrayColorTransform: nil)
        thresholdFilter.encode(commandBuffer: configuration.commandBuffer, sourceTexture: configuration.sourceTexture, destinationTexture: configuration.destinationTexture)
    }
}
