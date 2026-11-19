// Procedural Nocturnal Fireflies (Bioluminescent Lampyridae)
// Simulates tiny, delicate, twinkling golden-emerald fireflies anchored in world space near vegetation

#ifndef FIREFLIES_GLSL
#define FIREFLIES_GLSL

#ifdef NIGHT_FIREFLIES

float fireflyHash(vec3 p3) {
	p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 renderNocturnalFireflies(vec3 rayDir, float pixelDist, vec3 camPos, float time, float nightAmount, float rain, float swappedDepth) {
    // Only appear during clear nights
    if (nightAmount <= 0.05 || rain > 0.15) return vec3(0.0);

    // Rule 1: Never spawn in open sky (fireflies live in terrestrial vegetation)
    if (swappedDepth >= 1.0) return vec3(0.0);

    // Rule 2: Minimum distance from player
    // Absolutely NO fireflies within 6.5 meters of the player so they never follow or swarm around the player
    if (pixelDist < 7.0) return vec3(0.0);

    float maxD = min(pixelDist - 0.5, 36.0);
    if (maxD <= 7.0) return vec3(0.0);

    vec3 fireflyAccum = vec3(0.0);
    const float cellSize = 6.0; // Sparse 6-meter grid
    const vec3 fireflyBaseCol = vec3(0.60, 1.15, 0.20); // Bioluminescent warm golden-emerald

    // Sample along the ray starting 7 meters AWAY from player in world space
    for (int i = 0; i < 6; i++) {
        float sampleDist = 7.5 + float(i) * 4.6;
        if (sampleDist >= maxD) break;

        vec3 samplePos = camPos + rayDir * sampleDist;
        vec3 cell = floor(samplePos / cellSize);

        // Rare natural occurrence: only ~12% of cells contain a firefly
        float cellSeed = fireflyHash(cell * 0.137 + vec3(12.3, 45.6, 78.9));
        if (cellSeed < 0.88) continue;

        // Position offsets in world coordinates (anchored to the world, NOT the player)
        float px = fireflyHash(cell + vec3(1.1, 2.2, 3.3));
        float py = fireflyHash(cell + vec3(4.4, 5.5, 6.6));
        float pz = fireflyHash(cell + vec3(7.7, 8.8, 9.9));

        // Gentle, slow hovering motion
        vec3 drift = vec3(
            sin(time * 0.40 + px * 6.28318) * 0.65,
            sin(time * 0.65 + py * 6.28318) * 0.30,
            cos(time * 0.45 + pz * 6.28318) * 0.65
        );

        // Absolute world position
        vec3 fireflyPos = (cell + vec3(0.5)) * cellSize + drift;
        vec3 toFirefly = fireflyPos - camPos;

        // Project onto view ray
        float projT = dot(toFirefly, rayDir);
        if (projT < 6.5 || projT > maxD) continue;

        // Distance from ray to firefly center
        vec3 perpVec = toFirefly - rayDir * projT;
        float perpD2 = dot(perpVec, perpVec);

        // Angular size calculation: prevents fireflies from ever appearing large on screen
        // theta = perpD / projT (angular radius in radians)
        float angularDist = sqrt(perpD2) / projT;

        // Sharp angular threshold: tightly limited to a tiny pinpoint speck (1-2 pixels)
        if (angularDist < 0.0035) {
            // Natural biological pulsation (slow glow, soft pulse, resting period)
            float pulseTimer = time * 1.8 + px * 6.28318;
            float pulse = pow(clamp(sin(pulseTimer) * 0.5 + 0.5, 0.0, 1.0), 4.5);
            if (pulse <= 0.01) continue;

            // Micro pinpoint core (crisp 1-2 pixel spark) + faint halo
            float core = exp(-angularDist * angularDist * 1200000.0) * 3.0;
            float halo = exp(-angularDist * 1400.0) * 0.25;

            // Smooth fade so fireflies never pop in right near the player
            float playerFade = smoothstep(6.5, 10.0, projT);

            // Distance attenuation towards far limit
            float distFade = clamp(1.0 - projT / 36.0, 0.0, 1.0);

            fireflyAccum += fireflyBaseCol * (core + halo) * pulse * playerFade * distFade;
        }
    }

    return fireflyAccum * nightAmount * (1.0 - rain * 1.5) * FIREFLY_BRIGHTNESS;
}

#endif // NIGHT_FIREFLIES
#endif // FIREFLIES_GLSL
