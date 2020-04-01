//
//  EmptyFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//


class Filter {

    /// I must check what it is XD
    var hasCustomShader: Bool { false }

    /// This name must match filter function name in source
    var name: String { "default_shader" }

    /// When overriding, you can copy this source and implement this method by yourself
    var source: String? {
        """
        #include <metal_stdlib>
        using namespace metal;
        kernel void default_shader(texture2d<float, access::read> input [[texture(0)]],
                                 texture2d<float, access::write> output [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]])
        {
        float4 color = input.read(gid);
        output.write(float4(color.r, color.g, color.b, 1), gid);
        }
        """
    }

    /// Implement this method to provide custom parameters to encoder
    func manageParameters(configuration: FilteringComponents) { }
}
