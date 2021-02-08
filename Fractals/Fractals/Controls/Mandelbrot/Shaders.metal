//
//  Shaders.metal
//  iboxCore
//
//  Created by Oleh Piskorskyj on 25/05/2020.
//  Copyright © 2020 investbank. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SceneMatrices {
    float4x4 projectionMatrix;
    float4x4 viewModelMatrix;
};

struct VertexIn {
    packed_float3 position;
    packed_float3 color;
};

struct VertexOut {
    float4 computedPosition[[position]];
    float3 color;
};

vertex VertexOut basic_vertex(const device VertexIn *vertex_array[[buffer(0)]], const device SceneMatrices &scene_matrices[[buffer(1)]], unsigned int vid[[vertex_id]]) {
    float4x4 viewModelMatrix = scene_matrices.viewModelMatrix;
    float4x4 projectionMatrix = scene_matrices.projectionMatrix;
    
    VertexIn v = vertex_array[vid];
    
    VertexOut outVertex = VertexOut();
    outVertex.computedPosition = projectionMatrix * viewModelMatrix * float4(v.position, 1.0);
    outVertex.color = v.color;
    
    return outVertex;
}

fragment float4 basic_fragment(VertexOut interpolated[[stage_in]]) {
    return float4(interpolated.color, 1.0);
}
