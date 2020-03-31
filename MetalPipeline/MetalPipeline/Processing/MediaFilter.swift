//
//  MediaFilter.swift
//  MetalPipeline
//
//  Created by Ernest Chechelski on 31/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

class MediaFilter {
    
    var name: String { "default_shader" }

    var hasCustomShader: Bool { false}

    /// When overriding, you can copy this source and implement this method by yourself.
    var source: String? {
        """
        #include <metal_stdlib>
        using namespace metal;
        kernel void default_shader(texture2d<float, access::read> input [[texture(0)]],
                                 texture2d<float, access::write> output [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]])
        {}
        """
    }

    /// This method 
    func manageParameters(configuration: FilterConfiguration) {

    }
}
