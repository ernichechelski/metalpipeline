//
//  SepiaFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

final class SepiaFilter: Filter {

    override var name: String { "sepia_shader" }

    override var hasCustomShader: Bool { true }

    override var source: String? {
        """
        #include <metal_stdlib>
        using namespace metal;
        kernel void sepia_shader(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         const device float* data [[ buffer(0) ]],
                         uint2 gid [[thread_position_in_grid]])
        {
        float4 color = input.read(gid);
        float outputRed = (color.r * .393) + (color.g *.769) + (color.b * .189);
        float outputGreen = (color.r * .349) + (color.g *.686) + (color.b * .168);
        float outputBlue = (color.r * .272) + (color.g *.534) + (color.b * .131);
        output.write(float4(outputRed, outputGreen, outputBlue, 1), gid);
        }
        """
    }
}


