//
//  NothingFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//
//  Just copy data to output
//

final class NothingFilter: Filter {

    override var name: String { "nothing" }

    override var hasCustomShader: Bool { true }

    override var source: String? {
        """
        #include <metal_stdlib>
        using namespace metal;
        kernel void nothing(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         const device float* data [[ buffer(0) ]],
                         uint2 gid [[thread_position_in_grid]])
        {
        float4 color = input.read(gid);
        output.write(float4(color.r, color.g, color.b, 1), gid);
        }
        """
    }
}
