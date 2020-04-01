//
//  ColorFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//
//  Filter colors
//

import MetalKit

final class ColorFilter: Filter {

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

    private let r: CGFloat = 0 // Pass only red components
    private let g: CGFloat = 1 // Pass only green components
    private let b: CGFloat = 0 // Pass only blue components

    override func manageParameters(configuration: FilteringComponents) {
        var data = [CFloat(r), CFloat(g), CFloat(b)]
        let dataBuffer = configuration.view.device!.makeBuffer(bytes: &data, length: MemoryLayout.stride(ofValue: data), options: [])
        configuration.encoder.setBuffer(dataBuffer!, offset: 0, index: 0)
    }
}
