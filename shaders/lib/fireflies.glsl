// Procedural Nocturnal Fireflies (Bioluminescent Lampyridae)
// Simulates floating, flickering golden-emerald fireflies in the air and over vegetation at night

#ifndef FIREFLIES_GLSL
#define FIREFLIES_GLSL

#ifdef NIGHT_FIREFLIES

float fireflyHash(vec3 p3) {
	p3 = fract(p3 * 0.1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 renderNocturnalFireflies(vec3 rayDir, float pixelDist, vec3 camPos, float time, float nightAmount, float rain) {
    if (nightAmount <= 0.05 || rain > 0.15) return vec3(0.0);

    float maxD = min(pixelDist, 24.0);
    if (maxD <= 1.5) return vec3(0.0);

    vec3 fireflyAccum = vec3(0.0);
    const float cellSize = 3.8;
    const vec3 fireflyBaseCol = vec3(0.72, 1.05, 0.18); // Bioluminescent warm golden-green

    // Sample along the ray across 6 depth slices
    for (int i = 0; i < 6; i++) {
        float sampleDist = 2.5 + float(i) * 3.4;
        if (sampleDist >= maxD) break;

        vec3 samplePos = camPos + rayDir * sampleDist;
        vec3 cell = floor(samplePos / cellSize);

        // Occurrence probability: ~32% of cells contain a firefly
        float cellSeed = fireflyHash(cell * 0.137 + vec3(12.3, 45.6, 78.9));
        if (cellSeed < 0.68) continue;

        // Random phase and drift offsets within cell
        float px = fireflyHash(cell + vec3(1.1, 2.2, 3.3));
        float py = fireflyHash(cell + vec3(4.4, 5.5, 6.6));
        float pz = fireflyHash(cell + vec3(7.7, 8.8, 9.9));

        // Organic hovering motion with gentle vertical bobbing
        vec3 drift = vec3(
            sin(time * 0.72 + px * 6.28318) * 1.15,
            sin(time * 1.15 + py * 6.28318) * 0.55 + 0.35,
            cos(time * 0.82 + pz * 6.28318) * 1.15
        );

        vec3 fireflyPos = (cell + vec3(0.5)) * cellSize + drift;
        vec3 toFirefly = fireflyPos - camPos;

        // Project onto view ray
        float projT = dot(toFirefly, rayDir);
        if (projT < 1.2 || projT > maxD) continue;

        // Perpendicular distance from ray to firefly center
        vec3 perpVec = toFirefly - rayDir * projT;
        float perpD2 = dot(perpVec, perpVec);

        if (perpD2 < 0.16) {
            float perpD = sqrt(perpD2);

            // Natural bioluminescent pulse (slow fade-in, brief peak, smooth fade-out)
            float pulseTimer = time * 2.2 + px * 6.28318;
            float pulse = pow(sin(pulseTimer) * 0.5 + 0.5, 3.2);

            // Luminous point core + diffuse glowing halo
            float core = exp(-perpD2 * 240.0) * pulse * 2.5;
            float halo = exp(-perpD * 9.5) * pulse * 0.45;
            float distAtten = clamp(1.0 - projT / 24.0, 0.0, 1.0);

            fireflyAccum += fireflyBaseCol * (core + halo) * distAtten;
        }
    }

    return fireflyAccum * nightAmount * (1.0 - rain * 1.5) * FIREFLY_BRIGHTNESS;
}

#endif // NIGHT_FIREFLIES
#endif // FIREFLIES_GLSL
