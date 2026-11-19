vec3 GetHandLight(const in int itemId, const in vec3 playerPos, const in vec3 normal) {
    if (itemId <= 0) return vec3(0.0);

    vec3 lightColor = vec3(1.0, 0.60, 0.20);
    float lightRange = float(HANDHELD_LIGHT_RANGE);

    #if defined IS_LPV_ENABLED && defined MC_GL_EXT_shader_image_load_store
        uvec2 blockData = texelFetch(texBlockData, itemId, 0).rg;
        vec4 lightColorRange = unpackUnorm4x8(blockData.r);
        vec3 lpvCol = srgbToLinear(lightColorRange.rgb);
        float lpvRange = lightColorRange.a * 255.0;
        if (lpvRange > 0.0) {
            lightColor = lpvCol;
            lightRange = lpvRange;
        }
    #endif

    // Distinct specialized spectral colors for held items
    if (itemId == 1022 || itemId == 1023) {
        // Soul Lantern / Soul Torch: Spectral Ice Cyan
        lightColor = vec3(0.12, 0.72, 1.05);
    } else if (itemId == 1018) {
        // Redstone Torch: Vivid Crimson Red
        lightColor = vec3(1.05, 0.08, 0.04);
        lightRange = min(lightRange, 8.0);
    } else if (itemId == 1020) {
        // Sea Lantern: Crystal Pale Aqua
        lightColor = vec3(0.35, 0.95, 0.90);
    } else if (itemId == 1016) {
        // Lava Bucket: Molten Volcanic Amber
        lightColor = vec3(1.10, 0.40, 0.05);
    } else if (itemId == 1010) {
        // Glow Berries: Bioluminescent Golden-Yellow
        lightColor = vec3(1.00, 0.75, 0.20);
        lightRange = min(lightRange, 9.0);
    }

    float lightDist = length(playerPos);
    if (lightDist >= lightRange) return vec3(0.0);

    float falloff = pow(clamp(1.0 - lightDist / lightRange, 0.0, 1.0), 2.2);
    return lightColor * falloff * 1.35;
}

vec3 doBlockLightLighting(
    vec3 lightColor, float lightmap, float exposureValue,
    vec3 playerPos, vec3 lpvPos
){

    float lightmapCurve = pow(1.0-sqrt(1.0-clamp(lightmap,0.0,1.0)),2.0) * 2.0;
    
    vec3 blockLight = lightColor * lightmapCurve;

    #ifdef TORCHLIGHT_FLICKER
        float torchFlame = sin(frameTimeCounter * 5.8 + dot(playerPos.xz, vec2(1.7, 2.3))) * 0.032
                         + cos(frameTimeCounter * 8.4 + playerPos.y * 3.1) * 0.018
                         + sin(frameTimeCounter * 13.5 + dot(playerPos, vec3(0.5, 0.7, 0.9))) * 0.012;
        blockLight *= (1.0 + torchFlame * clamp(lightmap * 1.5, 0.0, 1.0));
    #endif
    
    #if defined IS_LPV_ENABLED && defined MC_GL_EXT_shader_image_load_store
        vec4 lpvSample = SampleLpvLinear(lpvPos);
        vec3 lpvBlockLight = GetLpvBlockLight(lpvSample);

        // create a smooth falloff at the edges of the voxel volume.
        float fadeLength = 10.0; // in meters
        vec3 cubicRadius = clamp( min(((LpvSize3-1.0) - lpvPos)/fadeLength,      lpvPos/fadeLength) ,0.0,1.0);
        float voxelRangeFalloff = cubicRadius.x*cubicRadius.y*cubicRadius.z;
        voxelRangeFalloff = 1.0 - pow(1.0-pow(voxelRangeFalloff,1.5),3.0);
        
        // outside the voxel volume, lerp to vanilla lighting as a fallback
        blockLight = mix(blockLight, lpvBlockLight/5.0, voxelRangeFalloff);

    #endif

    #ifdef Hand_Held_lights
        const vec3 handNormal = vec3(0.0);
        if (heldItemId > 0)
            blockLight += GetHandLight(heldItemId, playerPos, handNormal);
        if (heldItemId2 > 0)
            blockLight += GetHandLight(heldItemId2, playerPos, handNormal);
    #endif

    // try to make blocklight have consistent visiblity in different light levels.
    float autoBrightness = mix(1.0, 30.0,  clamp(exp(-10.0*exposureValue),0.0,1.0));
    blockLight *= autoBrightness;
    
    return blockLight * TORCH_AMOUNT;
}

vec3 doIndirectLighting(
    vec3 lightColor, vec3 minimumLightColor, float lightmap
){

    float lightmapCurve = (pow(lightmap,15.0)*2.0 + pow(lightmap,2.5))*0.5;

    vec3 indirectLight = lightColor * lightmapCurve * ambient_brightness * 0.7; 

    indirectLight += minimumLightColor * max(MIN_LIGHT_AMOUNT*0.01, nightVision * 0.1);

    return indirectLight;
}