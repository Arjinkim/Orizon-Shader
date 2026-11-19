//Original star code : https://www.shadertoy.com/view/Md2SR3 , optimised
//Enhanced with Photorealistic Flowing Aurora Curtains, Milky Way Galactic Core & Blackbody Stars

// Return random noise in the range [0.0, 1.0], as a function of x.
float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
//  1 out, 3 in...
float hash13(vec3 p3)
{
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Fast smooth 2D value noise for curtain folds and nebula wisps
float auroraNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Smooth 3D value noise for Milky Way and Aurora curtains
float starValueNoise(vec3 p)
{
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
    float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
    float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
    float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
    float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
    float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
    float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
    float n111 = hash13(i + vec3(1.0, 1.0, 1.0));

    float nx00 = mix(n000, n100, f.x);
    float nx10 = mix(n010, n110, f.x);
    float nx01 = mix(n001, n101, f.x);
    float nx11 = mix(n011, n111, f.x);

    float nxy0 = mix(nx00, nx10, f.y);
    float nxy1 = mix(nx01, nx11, f.y);

    return mix(nxy0, nxy1, f.z);
}

float starFbm(vec3 p)
{
    float v = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 3; i++) {
        v += amp * starValueNoise(p);
        p = p * 2.03 + vec3(13.7, 7.1, 19.3);
        amp *= 0.5;
    }
    return v;
}

// Convert Noise2d() into a "star field" by stomping everthing below fThreshhold to zero.
float NoisyStarField( in vec3 vSamplePos, float fThreshhold )
{
    float StarVal = hash13( vSamplePos );
    StarVal = clamp(StarVal/(1.0 - fThreshhold) - fThreshhold/(1.0 - fThreshhold),0.0,1.0);

    return StarVal;
}

// Stabilize NoisyStarField() by only sampling at integer values.
float StableStarField( in vec3 vSamplePos, float fThreshhold )
{
    float fractX = fract( vSamplePos.x );
    float fractY = fract( vSamplePos.y );
    vec3 floorSample = floor( vSamplePos.xyz );

    float v1 = NoisyStarField( floorSample, fThreshhold);
    float v2 = NoisyStarField( floorSample + vec3( 0.0, 1.0, 0.0), fThreshhold );
    float v3 = NoisyStarField( floorSample + vec3( 1.0, 0.0, 0.0), fThreshhold );
    float v4 = NoisyStarField( floorSample + vec3( 1.0, 1.0, 0.0), fThreshhold );

    float StarVal =   v1 * ( 1.0 - fractX ) * ( 1.0 - fractY )
        			+ v2 * ( 1.0 - fractX ) * fractY
        			+ v3 * fractX * ( 1.0 - fractY )
        			+ v4 * fractX * fractY;

	return StarVal;
}

float stars(vec3 viewPos){
    float stars = max(1.0 - StableStarField(viewPos*300.0 , 0.99),0.0);
	return exp( stars  * -20.0);
}

// Enhanced multi-layer stars with realistic stellar blackbody colors, clusters & twinkling
vec3 renderEnhancedStars(vec3 viewPos, float time) {
    vec3 sample1 = viewPos * 340.0;
    float primaryRaw = max(1.0 - StableStarField(sample1, 0.990), 0.0);
    float primaryStar = exp(primaryRaw * -20.0);

    vec3 cellId = floor(sample1);
    float tempHash  = hash13(cellId + vec3(17.3, 43.1, 9.7));
    float phaseHash = hash13(cellId + vec3(5.1, 89.2, 61.4));
    float magHash   = hash13(cellId + vec3(33.7, 11.9, 73.2));

    // Realistic stellar classification & blackbody tint:
    // O/B: Intense blue-white (15,000K+)
    // A/F: Pure crisp diamond white (8,000K)
    // G: Warm golden sun-like (5,500K)
    // K/M: Vibrant orange-red giant (3,500K)
    vec3 starColor = mix(vec3(0.65, 0.82, 1.00), vec3(1.00, 0.98, 0.95), clamp(tempHash * 2.2, 0.0, 1.0));
    starColor = mix(starColor, vec3(1.00, 0.68, 0.35), clamp(tempHash * 2.5 - 1.25, 0.0, 1.0));

    // Magnitude variation: brilliant prominent stars + dense star field
    float magnitude = 0.75 + 1.35 * pow(magHash, 3.2);

    // Natural atmospheric scintillation (independent star twinkle)
    float twinkle = 0.68 + 0.32 * sin(time * (2.2 + magHash * 3.1) + phaseHash * 6.2831853);

    // Faint unresolved background star cluster haze (milky cosmic dust)
    float secondaryRaw = max(1.0 - StableStarField(viewPos * 580.0 + vec3(23.1), 0.986), 0.0);
    float secondaryStar = exp(secondaryRaw * -24.0) * 0.42;

    // Pleiades-like open cluster accent
    vec3 clusterDir = normalize(vec3(0.35, 0.75, 0.55));
    float clusterDist = length(cross(viewPos, clusterDir));
    float clusterMask = exp(-clusterDist * clusterDist * 160.0);
    float clusterStars = max(1.0 - StableStarField(viewPos * 740.0, 0.981), 0.0);
    clusterStars = exp(clusterStars * -19.0) * clusterMask * 1.1;

    vec3 result = (primaryStar * magnitude * twinkle * starColor * 1.35) 
                + (secondaryStar * vec3(0.82, 0.90, 1.00))
                + (clusterStars * vec3(0.72, 0.88, 1.05));

    return result;
}

// Procedural Milky Way galactic band with galactic core bulge & dust rift
vec3 renderMilkyWay(vec3 orbitDir) {
    vec3 galacticNormal = normalize(vec3(0.45, 0.62, -0.64));
    float bandDist = abs(dot(orbitDir, galacticNormal));
    float bandEnvelope = exp(-bandDist * bandDist * 15.0);

    if (bandEnvelope < 0.002) return vec3(0.0);

    // Galactic center coordinates (Sagittarius A* core bulge)
    vec3 galacticCenter = normalize(vec3(-0.64, 0.18, 0.48));
    float coreDist = length(cross(orbitDir, galacticCenter));
    float coreBulge = exp(-coreDist * coreDist * 7.0) * exp(-bandDist * bandDist * 5.5);

    // Multi-octave stellar cloud structure
    float cloud1 = starFbm(orbitDir * 4.2);
    float cloud2 = starValueNoise(orbitDir * 8.5 + vec3(2.1, -1.4, 3.7));
    float cloudStructure = cloud1 * 0.68 + cloud2 * 0.32;

    // The Great Rift (dark interstellar absorption dust lanes)
    float dustNoise = starFbm(orbitDir * 8.0 + vec3(4.2, 1.8, -3.1));
    float dustLane = smoothstep(0.32, 0.66, dustNoise);
    float dustRift = 1.0 - (exp(-bandDist * bandDist * 50.0) * dustLane * 0.80);

    // Galactic colors: Warm amber-gold core + luminous violet-blue disk + faint H-II emission nebulae
    vec3 diskColor = vec3(0.15, 0.22, 0.45);
    vec3 coreColor = vec3(0.65, 0.48, 0.38);
    vec3 hAlphaPink = vec3(0.65, 0.16, 0.40);

    float hAlphaRegions = pow(clamp(starValueNoise(orbitDir * 12.0) - 0.62, 0.0, 1.0) * 3.0, 2.0);

    vec3 nebulaColor = mix(diskColor, coreColor, cloudStructure);
    nebulaColor += hAlphaPink * hAlphaRegions * 0.45;
    nebulaColor += coreColor * coreBulge * 2.2;

    float finalBrightness = bandEnvelope * cloudStructure * dustRift * 1.35;
    return nebulaColor * finalBrightness;
}

// Photorealistic flowing Northern Lights (Aurora Borealis) with animated dancing waves & ray shimmer
vec3 renderAuroraBorealis(vec3 viewDir, float time, float rain) {
    if (viewDir.y <= 0.02) return vec3(0.0);

    // Horizon fade & smooth zenith blend
    float horizonFade = smoothstep(0.02, 0.24, viewDir.y);
    float zenithFade = 1.0 - smoothstep(0.85, 1.0, viewDir.y) * 0.40;
    float weatherFade = clamp(1.0 - rain * 1.3, 0.0, 1.0);

    // Project view direction onto aurora altitude plane
    vec2 skyPos = viewDir.xz / max(viewDir.y + 0.06, 0.06);
    float x = skyPos.x;         // East-West axis
    float z = -skyPos.y;        // North-South axis (z > 0 is facing North)

    // Auroral zone mask: Aurora spans an expansive northern celestial canopy
    float northMask = smoothstep(-0.65, 0.35, z);
    if (northMask <= 0.001) return vec3(0.0);

    // Dynamic, visibly dancing animation speed
    float auroraTime = time * 0.16;
    vec3 auroraAccum = vec3(0.0);

    // Base arc shape across northern sky with multi-harmonic flowing waves
    float baseArc = 1.90 + 0.10 * (x * x);
    float mainWave = sin(x * 0.52 + auroraTime * 1.35) * 0.58 
                   + sin(x * 1.15 - auroraTime * 0.85) * 0.30 
                   + auroraNoise(vec2(x * 0.40, auroraTime * 0.45)) * 0.48;

    // Soft atmospheric diffuse glow around the aurora belt
    float beltDist = abs(z - (baseArc + mainWave * 0.5));
    float diffuseGlow = exp(-beltDist * 0.75) * smoothstep(0.05, 0.42, viewDir.y) * 0.35;
    vec3 diffuseCol = vec3(0.04, 0.36, 0.24);

    // Realistic color palette across altitude layers:
    // Base: Pure luminous emerald green (557.7 nm atomic oxygen)
    const vec3 cEmerald = vec3(0.06, 1.05, 0.46);
    // Lower-mid: Vibrant aquamarine / cyan
    const vec3 cCyan    = vec3(0.04, 0.88, 0.94);
    // Upper-mid: Ethereal deep violet / royal purple
    const vec3 cViolet  = vec3(0.55, 0.18, 0.98);
    // Top crown: High-altitude crimson / magenta / rose (630.0 nm atomic oxygen)
    const vec3 cCrimson = vec3(0.96, 0.14, 0.54);

    // Raymarch through 5 vertical altitude layers (curtain folds & dancing rays)
    for (int i = 0; i < 5; i++) {
        float h = float(i) / 4.0; // Normalized altitude: 0 = base (~100km), 1 = crown (~250km)

        // Curtain drift with altitude (magnetic field line inclination)
        float drift = h * (0.38 * sin(x * 0.35 + auroraTime * 0.9) + 0.22);

        // --- PRIMARY DANCING CURTAIN ---
        float ribbonCenter1 = baseArc + mainWave + drift;
        float d1 = abs(z - ribbonCenter1);

        // Vertical rays / shimmering chiffon folds dancing horizontally
        float rayCoord = x * 4.2 + auroraTime * 1.5;
        float rayDetail = auroraNoise(vec2(rayCoord, h * 5.8 - auroraTime * 2.1));
        float foldPattern = 0.35 + 0.65 * sin(rayCoord * 2.1 + rayDetail * 5.0 + sin(auroraTime * 1.6 + x) * 0.7);
        foldPattern = pow(clamp(foldPattern, 0.0, 1.0), 2.1);

        // Curtain profile: sharp, dense base transitioning to ethereal diffuse top
        float thickness1 = 0.15 + h * 0.35;
        float profile1 = exp(-d1 * d1 / (thickness1 * thickness1));
        float baseIntensity1 = exp(-h * 2.0) * 1.7;
        float bodyIntensity1 = (1.0 - h * 0.35) * (0.35 + 0.65 * foldPattern);
        float curtainAlpha1 = profile1 * (baseIntensity1 + bodyIntensity1);

        // --- SECONDARY DANCING CURTAIN (Parallel background ribbon) ---
        float ribbonCenter2 = baseArc + 0.92 + sin(x * 0.62 - auroraTime * 1.15) * 0.44 + drift * 0.85;
        float d2 = abs(z - ribbonCenter2);
        float rayCoord2 = x * 3.2 - auroraTime * 1.05;
        float foldPattern2 = pow(clamp(0.40 + 0.60 * sin(rayCoord2 * 2.5 + h * 4.2 + auroraTime * 0.8), 0.0, 1.0), 1.9);
        float thickness2 = 0.18 + h * 0.40;
        float profile2 = exp(-d2 * d2 / (thickness2 * thickness2));
        float curtainAlpha2 = profile2 * (1.0 - h * 0.42) * (0.3 + 0.7 * foldPattern2) * 0.65;

        // Altitude color blending
        vec3 layerCol = mix(cEmerald, cCyan, smoothstep(0.06, 0.40, h));
        layerCol = mix(layerCol, cViolet, smoothstep(0.36, 0.74, h));
        layerCol = mix(layerCol, cCrimson, smoothstep(0.68, 0.98, h));

        auroraAccum += layerCol * (curtainAlpha1 + curtainAlpha2) * 0.28;
    }

    auroraAccum += diffuseCol * diffuseGlow;

    return auroraAccum * horizonFade * zenithFade * northMask * weatherFade * AURORA_BRIGHTNESS;
}

// Dynamic Nocturnal Shooting Stars (Meteors)
vec3 renderShootingStars(vec3 viewDir, float time) {
    if (viewDir.y <= 0.05) return vec3(0.0);

    // Each meteor event occurs every ~6.5 seconds
    float cycle = 6.5;
    float tCycle = mod(time, cycle);
    float meteorId = floor(time / cycle);

    // Visible duration of each meteor streak is ~0.55s
    float meteorDuration = 0.55;
    if (tCycle > meteorDuration) return vec3(0.0);

    // Pseudo-random start direction and velocity trajectory across the sky
    float seedX = hash12(vec2(meteorId * 13.7, 47.1));
    float seedY = hash12(vec2(meteorId * 29.3, 83.5));
    float seedZ = hash12(vec2(meteorId * 71.9, 19.3));

    // Direction on upper hemisphere
    vec3 meteorStart = normalize(vec3((seedX - 0.5) * 1.8, 0.45 + seedY * 0.45, (seedZ - 0.5) * 1.8));
    vec3 meteorDir = normalize(vec3((seedZ - 0.5) * 1.2, -0.65 - seedX * 0.45, (seedX - 0.5) * 1.2));

    float progress = tCycle / meteorDuration;
    float streakLength = 0.22; // Arc length of the glowing ionization trail

    vec3 headPos = normalize(meteorStart + meteorDir * progress * 0.95);
    vec3 tailPos = normalize(meteorStart + meteorDir * max(0.0, progress * 0.95 - streakLength));

    // Distance from viewDir to the 3D line segment on celestial sphere
    vec3 v = viewDir;
    vec3 a = tailPos;
    vec3 b = headPos;
    vec3 ab = b - a;
    float tSeg = clamp(dot(v - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
    vec3 closestPoint = a + ab * tSeg;
    float distToStreak = length(v - normalize(closestPoint));

    // Streak appearance: brilliant radiant white-cyan head with fading soft tail
    if (distToStreak < 0.006) {
        float coreRadius = 0.0018;
        float tailTaper = pow(tSeg, 1.8); // Brighter towards the head
        float core = exp(-pow(distToStreak / coreRadius, 2.0)) * tailTaper;
        float halo = exp(-distToStreak * 350.0) * tailTaper * 0.35;

        vec3 meteorColor = mix(vec3(0.55, 0.85, 1.20), vec3(1.10, 1.05, 0.95), tSeg);
        return meteorColor * (core * 8.0 + halo * 2.0);
    }

    return vec3(0.0);
}
