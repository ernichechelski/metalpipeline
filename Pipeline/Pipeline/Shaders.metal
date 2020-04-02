#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float4 position [[ attribute(0) ]];
};

vertex float4 vertex_main(const VertexIn vertexIn [[ stage_in ]],
                          constant float &timer [[ buffer(1) ]]) {
    float4 position = vertexIn.position;
    position.y += timer;
    return position;
}

/// Returns position of the vertex modified by offests array
vertex float4 vertex_advanced(const VertexIn vertexIn [[ stage_in ]],
                              constant float3 &offsets [[ buffer(1) ]]) {
    float4 position = vertexIn.position;
    position.y += offsets[0];
    position.x += offsets[1];
    position.z += offsets[2];
    return position;
}

/// Returns color of the fragment, by just ignoring parameter
fragment float4 fragment_main() {
    return float4(1, 1, 1, 1);
}

/// Returns color of the fragment
fragment float4 fragment_color(constant float4 &color [[ buffer(0) ]]) {
    return color;
}
