//
//  ColorFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

import Metal
import MetalKit
import MetalPerformanceShaders

class ColorFilter: MediaFilter {

    override var name: String { "color_shader" }

    override var hasCustomShader: Bool { true }

    override var source: String? {
        """
        #include <metal_stdlib>
        using namespace metal;
        kernel void color_shader(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         const device float* data [[ buffer(0) ]],
                         uint2 gid [[thread_position_in_grid]])
        {
        float4 color = input.read(gid);
        float average = (color.r + color.g + color.b) / 3.0;
        float4 grayScale = float4(average, average, average, 1.0);
        float4 colorToApply = float4(data[0], data[1], data[2], 1.0);
        float4 result = grayScale * colorToApply;
        output.write(float4(result.r, result.g, result.b, 1), gid);
        }
        """
    }

    var r: CGFloat = 0.0
    var g: CGFloat = 0.0
    var b: CGFloat = 0.0

    override func manageParameters(configuration: FilterConfiguration) {
        let colorFilter = self
        var data = [CFloat(colorFilter.r), CFloat(colorFilter.g), CFloat(colorFilter.b)]
        let dataBuffer = configuration.view.device!.makeBuffer(bytes: &data, length: MemoryLayout.stride(ofValue: data), options: [])
        configuration.encoder.setBuffer(dataBuffer!, offset: 0, index: 0)
    }
}
