// Atmospheric Dispersion Rainbow Model (Primary & Secondary Rainbow with Alexander's Dark Band)
// Physical angular dispersion around the anti-solar axis: Primary at ~42°, Secondary at ~51°

#ifndef RAINBOW_GLSL
#define RAINBOW_GLSL

#ifdef DYNAMIC_RAINBOWS

vec3 renderDynamicRainbow(vec3 viewDir, vec3 sunVector, float rain, float time) {
    // Requires sunlight and atmospheric moisture/rain
    if (rain <= 0.01 || sunVector.y <= 0.02 || viewDir.y <= 0.01) return vec3(0.0);

    vec3 antiSun = normalize(-sunVector);
    float cosAngle = dot(viewDir, antiSun);
    float angleRad = acos(clamp(cosAngle, -1.0, 1.0));
    float angleDeg = angleRad * 57.2957795; // Radians to degrees

    // Primary Rainbow (~40.0° to 42.5°)
    // Spectral wavelengths: Red (~42.3°), Orange (~41.9°), Green (~41.4°), Cyan (~40.9°), Blue/Violet (~40.4°)
    float redPeak1   = exp(-pow((angleDeg - 42.3) / 0.38, 2.0));
    float greenPeak1 = exp(-pow((angleDeg - 41.5) / 0.42, 2.0));
    float bluePeak1  = exp(-pow((angleDeg - 40.7) / 0.44, 2.0));
    vec3 primaryRainbow = vec3(redPeak1 * 1.05 + greenPeak1 * 0.15, greenPeak1 * 0.95 + redPeak1 * 0.25, bluePeak1 * 1.15);

    // Secondary Rainbow (~50.0° to 53.0°, inverted color order & fainter)
    float redPeak2   = exp(-pow((angleDeg - 50.8) / 0.55, 2.0));
    float greenPeak2 = exp(-pow((angleDeg - 51.7) / 0.58, 2.0));
    float bluePeak2  = exp(-pow((angleDeg - 52.6) / 0.62, 2.0));
    vec3 secondaryRainbow = vec3(redPeak2 * 1.0 + greenPeak2 * 0.15, greenPeak2 * 0.95 + redPeak2 * 0.2, bluePeak2 * 1.10) * 0.38;

    // Horizon fade and altitude shaping
    float horizonFade = smoothstep(0.01, 0.18, viewDir.y);
    float sunAltitudeFactor = smoothstep(0.02, 0.45, sunVector.y) * (1.0 - smoothstep(0.65, 0.95, sunVector.y));
    float rainIntensity = smoothstep(0.02, 0.50, rain) * (1.0 - smoothstep(0.85, 1.0, rain) * 0.4);

    vec3 totalRainbow = (primaryRainbow + secondaryRainbow) * horizonFade * sunAltitudeFactor * rainIntensity;
    return totalRainbow * RAINBOW_BRIGHTNESS;
}

#endif // DYNAMIC_RAINBOWS
#endif // RAINBOW_GLSL
