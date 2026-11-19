// Cinematic Anamorphic & Spherical Lens Flare System
// Computes optical reflections, aperture rings, and anamorphic bloom along the lens optical axis

#ifndef LENS_FLARE_GLSL
#define LENS_FLARE_GLSL

#ifdef CINEMATIC_LENS_FLARE

vec3 renderCinematicLensFlare(vec2 uv, vec2 sunScreenPos, float sunVisible, float aspectRatio) {
    if (sunVisible <= 0.001) return vec3(0.0);

    vec2 toCenter = vec2(0.5) - sunScreenPos;
    vec2 flareAxis = toCenter;
    
    vec2 uvAspect = (uv - vec2(0.5)) * vec2(aspectRatio, 1.0) + vec2(0.5);
    vec2 sunAspect = (sunScreenPos - vec2(0.5)) * vec2(aspectRatio, 1.0) + vec2(0.5);

    vec3 flareAccum = vec3(0.0);

    // 1. Primary Sun Halo / Aperture Ring around the Sun
    float sunDist = length(uvAspect - sunAspect);
    float ringRadius = 0.16;
    float ring = exp(-pow((sunDist - ringRadius) / 0.018, 2.0)) * 0.22;
    vec3 ringColor = vec3(1.0, 0.65, 0.35) * ring;

    // 2. Anamorphic Horizontal Glow Streak through Sun Center
    vec2 dSun = uvAspect - sunAspect;
    float streakY = abs(dSun.y);
    float streakX = abs(dSun.x);
    float streak = exp(-streakY * 95.0) * exp(-streakX * 2.5) * 0.35;
    vec3 streakColor = vec3(0.45, 0.75, 1.20) * streak;

    // 3. Secondary Ghosts along the optical axis through screen center
    const float ghostOffsets[4] = float[4](0.35, 0.65, 1.15, 1.45);
    const vec3 ghostColors[4] = vec3[4](
        vec3(0.35, 0.75, 1.10), // Pale cyan
        vec3(0.95, 0.55, 0.25), // Golden amber
        vec3(0.40, 0.90, 0.50), // Emerald
        vec3(0.85, 0.35, 0.95)  // Violet
    );
    const float ghostSizes[4] = float[4](0.035, 0.055, 0.040, 0.080);

    for (int i = 0; i < 4; i++) {
        vec2 ghostPos = sunScreenPos + flareAxis * ghostOffsets[i];
        vec2 ghostPosAspect = (ghostPos - vec2(0.5)) * vec2(aspectRatio, 1.0) + vec2(0.5);
        float dGhost = length(uvAspect - ghostPosAspect);
        float ghostIntensity = exp(-pow(dGhost / ghostSizes[i], 2.0));
        flareAccum += ghostColors[i] * ghostIntensity * 0.18;
    }

    flareAccum += ringColor + streakColor;

    // Screen edge fade so flare does not hard-cut at window borders
    float edgeFade = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x)
                   * smoothstep(0.0, 0.08, uv.y) * smoothstep(1.0, 0.92, uv.y);

    return flareAccum * sunVisible * edgeFade * LENS_FLARE_BRIGHTNESS;
}

#endif // CINEMATIC_LENS_FLARE
#endif // LENS_FLARE_GLSL
