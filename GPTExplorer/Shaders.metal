//
//  Shaders.metal
//  GPTExplorer
//
//  Created by James Rochabrun on 12/5/23.
//

#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] half4
angledFill(float2 position, float width, float angle, half4 color)
{
    float pMagnitude = sqrt(position.x * position.x + position.y * position.y);
    float pAngle = angle +
        (position.x == 0.0f ? (M_PI_F / 2.0f) : atan(position.y / position.x));
    float rotatedX = pMagnitude * cos(pAngle);
    float rotatedY = pMagnitude * sin(pAngle);
    return (color + color * fmod(abs(rotatedX + rotatedY), width) / width) / 2;
}

[[ stitchable ]] half4 circleLoader(
    float2 position,
    half4 color,
    float4 bounds,
    float secs
) {
    float cols = 6;
    float PI2 = 6.2831853071795864769252867665590;
    float timeScale = 0.04;

    vector_float2 uv = position/bounds.zw;

    float circle_rows = (cols * bounds.w) / bounds.z;
    float scaledTime = secs * timeScale;

    float circle = -cos((uv.x - scaledTime) * PI2 * cols) * cos((uv.y + scaledTime) * PI2 * circle_rows);
    float stepCircle = step(circle, -sin(secs + uv.x - uv.y));

    // Blue Colors
   vector_float4 circles = vector_float4(1.0, 1.0, 1.0, 1.0);//vector_float4(0.196, 0.051, 0.706, 1.0);
   vector_float4 background = vector_float4(0.0, 0.0, 0.0, 1.0);//vector_float4(0.2157, 0.6392, 0.4980, 1.0);
//vector_float4(0.357, 0.525, 0.969, 1.0);

    return half4(mix(background, circles, stepCircle));
}


[[ stitchable ]] half4 circleWaveTransition(float2 position, half4 color, float2 size, float amount, float circleSize) {
    // Calculate our coordinate in UV space, 0 to 1.
    half2 uv = half2(position / size);

    // Figure out our position relative to the nearest
    // circle.
    half2 f = half2(fract(position / circleSize));

    // Calculate the Euclidean distance from this pixel
    // to the center of the nearest circle.
    half d = distance(f, 0.5);

    // If the transition has progressed beyond our distance,
    // factoring in our X/Y UV coordinate…
    if (d + uv.x + uv.y < amount * 3.0) {
        // Send back the color
        return color;
    } else {
        // Otherwise send back clear.
        return half4(0.0h);
    }
}
