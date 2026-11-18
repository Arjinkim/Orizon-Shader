#ifndef ORE_MATERIALS_GLSL
#define ORE_MATERIALS_GLSL

/*
 * Next-Gen Auto-PBR & Mineral Specular Generator
 * Strictly targets ore blocks defined in block.properties (IDs 600..609 and 101..103).
 * Leaves all normal stone, dirt, granite, diorite, andesite 100% untouched.
 */

uniform float frameTimeCounter;

float ore_max3(vec3 v) { return max(max(v.r, v.g), v.b); }
float ore_min3(vec3 v) { return min(min(v.r, v.g), v.b); }

void computeAutoOrePBR(
    vec3 albedo,
    vec3 worldPos,
    int blockID,
    inout float roughness,
    inout float f0,
    inout float emissive,
    inout vec3 normal,
    mat3 tbnMatrix
) {
    // STRICT GUARD: ONLY execute for confirmed Ore & Amethyst block IDs!
    // Never touch normal stone (0), dirt (0), granite (0), diorite (0), foliage, etc.
    bool isTargetOre = (blockID >= 600 && blockID <= 609) || (blockID >= 101 && blockID <= 103);
    if (!isTargetOre) return;

    // If a LabPBR resource pack already defined specular properties, respect them
    if (roughness > 0.08 || f0 > 0.08) return;

    #if defined ENTITIES || defined BLOCKENTITIES || defined HAND
    return;
    #endif

    float cMax = ore_max3(albedo);
    float cMin = ore_min3(albedo);
    float cDelta = cMax - cMin;
    float sat = cMax > 0.001 ? cDelta / cMax : 0.0;
    float lum = dot(albedo, vec3(0.299, 0.587, 0.114));

    // Pseudorandom facet tilt per block + sub-texel coordinate
    vec3 pBlock = floor(worldPos * 16.0);
    float facetHash1 = sin(dot(pBlock, vec3(12.9898, 78.233, 45.164))) * 43758.5453;
    float facetHash2 = cos(dot(pBlock, vec3(39.346, 11.135, 71.564))) * 24634.6345;
    vec2 facetTilt = (fract(vec2(facetHash1, facetHash2)) - 0.5) * 0.45;

    bool isOrePixel = false;

    // 607: DIAMOND ORE / DIAMOND BLOCK
    if (blockID == 607) {
        // Only cyan diamond crystals, not the surrounding stone
        if (sat > 0.20 && albedo.b > albedo.r * 1.25) {
            roughness = 0.06;
            f0 = 0.45;
            #ifdef ORE_CAVE_LUMINESCENCE
            emissive = 0.18 + 0.08 * sin(frameTimeCounter * 1.6 + dot(pBlock, vec3(0.7)));
            #endif
            isOrePixel = true;
        }
    }
    // 605: EMERALD ORE / EMERALD BLOCK
    else if (blockID == 605) {
        if (sat > 0.22 && albedo.g > albedo.r * 1.25 && albedo.g > albedo.b * 1.15) {
            roughness = 0.08;
            f0 = 0.38;
            #ifdef ORE_CAVE_LUMINESCENCE
            emissive = 0.14 + 0.06 * cos(frameTimeCounter * 1.4 + dot(pBlock, vec3(0.5)));
            #endif
            isOrePixel = true;
        }
    }
    // 603: GOLD ORE / NETHER GOLD / GOLD BLOCK
    else if (blockID == 603) {
        if (sat > 0.25 && albedo.r > 0.45 && albedo.g > 0.30 && albedo.b < 0.40) {
            roughness = 0.12;
            f0 = 0.94; // Metallic Gold
            isOrePixel = true;
        }
    }
    // 602: COPPER ORE / COPPER BLOCK
    else if (blockID == 602) {
        if (sat > 0.22 && albedo.r > 0.42 && albedo.g > 0.18 && albedo.b < 0.35) {
            roughness = 0.16;
            f0 = 0.92; // Metallic Copper
            isOrePixel = true;
        }
    }
    // 604: REDSTONE ORE / REDSTONE BLOCK
    else if (blockID == 604) {
        if (sat > 0.20 && albedo.r > max(albedo.g, albedo.b) * 1.35) {
            roughness = 0.10;
            f0 = 0.35;
            #ifdef ORE_CAVE_LUMINESCENCE
            emissive = 0.32 + 0.18 * sin(frameTimeCounter * 2.8 + dot(pBlock, vec3(1.1)));
            #endif
            isOrePixel = true;
        }
    }
    // 606: LAPIS ORE / LAPIS BLOCK
    else if (blockID == 606) {
        if (sat > 0.20 && albedo.b > max(albedo.r, albedo.g) * 1.25) {
            roughness = 0.14;
            f0 = 0.32;
            #ifdef ORE_CAVE_LUMINESCENCE
            emissive = 0.12 + 0.05 * sin(frameTimeCounter * 1.2 + dot(pBlock, vec3(0.9)));
            #endif
            isOrePixel = true;
        }
    }
    // 601: IRON ORE / IRON BLOCK
    else if (blockID == 601) {
        if (sat > 0.12 && albedo.r > 0.45 && (albedo.r - albedo.b) > 0.08) {
            roughness = 0.20;
            f0 = 0.88; // Metallic Iron
            isOrePixel = true;
        }
    }
    // 608: NETHER QUARTZ ORE / QUARTZ BLOCK
    else if (blockID == 608) {
        if (lum > 0.75 && sat < 0.12) {
            roughness = 0.07;
            f0 = 0.30;
            isOrePixel = true;
        }
    }
    // 609: ANCIENT DEBRIS / NETHERITE BLOCK
    else if (blockID == 609) {
        roughness = 0.22;
        f0 = 0.90;
        isOrePixel = true;
    }
    // 600: COAL ORE
    else if (blockID == 600) {
        if (lum < 0.22) {
            roughness = 0.35;
            f0 = 0.08;
            isOrePixel = true;
        }
    }
    // 101..103: AMETHYST CLUSTER & BUDS
    else if (blockID >= 101 && blockID <= 103) {
        roughness = 0.05;
        f0 = 0.40;
        #ifdef ORE_CAVE_LUMINESCENCE
        emissive = 0.20 + 0.10 * sin(frameTimeCounter * 1.8 + dot(pBlock, vec3(0.8)));
        #endif
        isOrePixel = true;
    }

    #ifdef ORE_CRYSTAL_FACET_SPARKLE
    if (isOrePixel) {
        vec3 tangentTilt = normalize(vec3(facetTilt.x, facetTilt.y, 0.88));
        normal = normalize(tbnMatrix * tangentTilt);
    }
    #endif
}

#endif // ORE_MATERIALS_GLSL
