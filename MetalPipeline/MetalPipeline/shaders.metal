//
//  shaders.metal
//  MetalPipeline
//
//  Created by Ernest Chechelski on 30/03/2020.
//  Copyright © 2020 Ernest Chechelski. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void compute_shader(texture2d<float, access::read> input [[texture(0)]],
                           texture2d<float, access::write> output [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]])
{

    float4 color = input.read(gid);
    output.write(float4(color.r, color.g, color.b, 1), gid);
}


