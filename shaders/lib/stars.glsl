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
    vec3 sample1 = viewPos * 320.0;
    float primaryRaw = max(1.0 - StableStarField(sample1, 0.991), 0.0);
    float primaryStar = exp(primaryRaw * -22.0);

    vec3 cellId = floor(sample1);
    float tempHash = hash13(cellId + vec3(17.3, 43.1, 9.7));
    float phaseHash = hash13(cellId + vec3(5.1, 89.2, 61.4));
    float magHash = hash13(cellId + vec3(33.7, 11.9, 73.2));

    // Realistic stellar classification & blackbody tint:
    // O/B: Intense blue-white (15,000K+)
    // A/F: Pure crisp diamond white (8,000K)
    // G: Warm golden sun-like (5,500K)
    // K/M: Vibrant orange-red giant (3,500K)
    vec3 starColor = mix(vec3(0.68, 0.82, 1.00), vec3(1.00, 0.98, 0.94), clamp(tempHash * 2.2, 0.0, 1.0));
    starColor = mix(starColor, vec3(1.00, 0.70, 0.38), clamp(tempHash * 2.5 - 1.3, 0.0, 1.0));

    // Magnitude variation: a few brilliant standout stars + many finer stars
    float magnitude = 0.65 + 0.95 * pow(magHash, 3.5);

    // Natural atmospheric scintillation (independent star twinkle)
    float twinkle = 0.76 + 0.24 * sin(time * (1.8 + magHash * 2.2) + phaseHash * 6.2831853);

    // Faint unresolved background star cluster haze (milky cosmic dust)
    float secondaryRaw = max(1.0 - StableStarField(viewPos * 560.0 + vec3(23.1), 0.987), 0.0);
    float secondaryStar = exp(secondaryRaw * -25.0) * 0.32;

    // Pleiades-like open cluster accent
    vec3 clusterDir = normalize(vec3(0.35, 0.75, 0.55));
    float clusterDist = length(cross(viewPos, clusterDir));
    float clusterMask = exp(-clusterDist * clusterDist * 160.0);
    float clusterStars = max(1.0 - StableStarField(viewPos * 720.0, 0.982), 0.0);
    clusterStars = exp(clusterStars * -20.0) * clusterMask * 0.85;

    vec3 result = (primaryStar * magnitude * twinkle * starColor) 
                + (secondaryStar * vec3(0.80, 0.88, 1.00))
                + (clusterStars * vec3(0.70, 0.85, 1.00));

    return result;
}

// Procedural Milky Way galactic band with galactic core bulge & dust rift
vec3 renderMilkyWay(vec3 orbitDir) {
    vec3 galacticNormal = normalize(vec3(0.45, 0.62, -0.64));
    float bandDist = abs(dot(orbitDir, galacticNormal));
    float bandEnvelope = exp(-bandDist * bandDist * 16.0);

    if (bandEnvelope < 0.003) return vec3(0.0);

    // Galactic center coordinates (Sagittarius A* core bulge)
    vec3 galacticCenter = normalize(vec3(-0.64, 0.18, 0.48));
    float coreDist = length(cross(orbitDir, galacticCenter));
    float coreBulge = exp(-coreDist * coreDist * 7.5) * exp(-bandDist * bandDist * 6.0);

    // Multi-octave stellar cloud structure
    float cloud1 = starFbm(orbitDir * 4.2);
    float cloud2 = starValueNoise(orbitDir * 8.5 + vec3(2.1, -1.4, 3.7));
    float cloudStructure = cloud1 * 0.7 + cloud2 * 0.3;

    // The Great Rift (dark interstellar absorption dust lanes)
    float dustNoise = starFbm(orbitDir * 8.0 + vec3(4.2, 1.8, -3.1));
    float dustLane = smoothstep(0.35, 0.65, dustNoise);
    float dustRift = 1.0 - (exp(-bandDist * bandDist * 55.0) * dustLane * 0.82);

    // Galactic colors: Warm amber core + luminous violet-blue disk + faint H-II emission nebulae
    vec3 diskColor = vec3(0.12, 0.18, 0.36);
    vec3 coreColor = vec3(0.48, 0.34, 0.38);
    vec3 hAlphaPink = vec3(0.55, 0.14, 0.32);

    float hAlphaRegions = pow(clamp(starValueNoise(orbitDir * 12.0) - 0.65, 0.0, 1.0) * 3.0, 2.0);

    vec3 nebulaColor = mix(diskColor, coreColor, cloudStructure);
    nebulaColor += hAlphaPink * hAlphaRegions * 0.35;
    nebulaColor += coreColor * coreBulge * 1.6;

    float finalBrightness = bandEnvelope * cloudStructure * dustRift * 0.46;
    return nebulaColor * finalBrightness;
}

// Photorealistic flowing Northern Lights (Aurora Borealis) ribbon curtains
vec3 renderAuroraBorealis(vec3 viewDir, float time, float rain) {
    if (viewDir.y <= 0.02) return vec3(0.0);

    // Horizon fade & smooth zenith blend
    float horizonFade = smoothstep(0.02, 0.22, viewDir.y);
    float zenithFade = 1.0 - smoothstep(0.85, 1.0, viewDir.y) * 0.45;
    float weatherFade = clamp(1.0 - rain * 1.3, 0.0, 1.0);

    // Project view direction onto aurora altitude plane
    vec2 skyPos = viewDir.xz / max(viewDir.y + 0.06, 0.06);
    float x = skyPos.x;         // East-West axis
    float z = -skyPos.y;        // North-South axis (z > 0 is facing North)

    // Auroral zone mask: Aurora naturally spans the Northern sky
    float northMask = smoothstep(-0.35, 0.55, z);
    if (northMask <= 0.001) return vec3(0.0);

    float slowTime = time * 0.038;
    vec3 auroraAccum = vec3(0.0);

    // Base arc shape across northern sky (arched parabolic ribbon)
    float baseArc = 1.95 + 0.11 * (x * x);
    float mainWave = sin(x * 0.42 + slowTime * 1.25) * 0.52 
                   + sin(x * 0.88 - slowTime * 0.75) * 0.24 
                   + auroraNoise(vec2(x * 0.35, slowTime * 0.4)) * 0.45;

    // Soft atmospheric diffuse glow around the aurora belt
    float beltDist = abs(z - (baseArc + mainWave * 0.5));
    float diffuseGlow = exp(-beltDist * 0.85) * smoothstep(0.05, 0.4, viewDir.y) * 0.28;
    vec3 diffuseCol = vec3(0.03, 0.28, 0.20);

    // Realistic color palette across altitude layers:
    // Base: Pure luminous emerald green (557.7 nm atomic oxygen)
    const vec3 cEmerald = vec3(0.05, 0.98, 0.44);
    // Lower-mid: Vibrant aquamarine / cyan
    const vec3 cCyan    = vec3(0.03, 0.82, 0.86);
    // Upper-mid: Ethereal deep violet / royal purple
    const vec3 cViolet  = vec3(0.48, 0.16, 0.92);
    // Top crown: High-altitude crimson / magenta / rose (630.0 nm atomic oxygen)
    const vec3 cCrimson = vec3(0.86, 0.12, 0.48);

    // Raymarch through 5 vertical altitude layers (curtain folds & rays)
    for (int i = 0; i < 5; i++) {
        float h = float(i) / 4.0; // Normalized altitude: 0 = base (~100km), 1 = crown (~250km)

        // Curtain drift with altitude (magnetic field line inclination)
        float drift = h * (0.35 * sin(x * 0.32 + slowTime * 0.8) + 0.2);

        // --- PRIMARY CURTAIN ---
        float ribbonCenter1 = baseArc + mainWave + drift;
        float d1 = abs(z - ribbonCenter1);

        // Vertical rays / chiffon folds following magnetic field lines
        float rayCoord = x * 3.6 + slowTime * 1.1;
        float rayDetail = auroraNoise(vec2(rayCoord, h * 5.2 - slowTime * 1.8));
        float foldPattern = 0.40 + 0.60 * sin(rayCoord * 1.8 + rayDetail * 4.8);
        foldPattern = pow(clamp(foldPattern, 0.0, 1.0), 1.9);

        // Curtain profile: sharp, dense base transitioning to ethereal diffuse top
        float thickness1 = 0.14 + h * 0.32;
        float profile1 = exp(-d1 * d1 / (thickness1 * thickness1));
        float baseIntensity1 = exp(-h * 2.2) * 1.6;
        float bodyIntensity1 = (1.0 - h * 0.38) * (0.35 + 0.65 * foldPattern);
        float curtainAlpha1 = profile1 * (baseIntensity1 + bodyIntensity1);

        // --- SECONDARY CURTAIN (Parallel background ribbon for realistic depth) ---
        float ribbonCenter2 = baseArc + 0.95 + sin(x * 0.55 - slowTime * 1.05) * 0.38 + drift * 0.8;
        float d2 = abs(z - ribbonCenter2);
        float rayCoord2 = x * 2.8 - slowTime * 0.9;
        float foldPattern2 = pow(clamp(0.45 + 0.55 * sin(rayCoord2 * 2.2 + h * 4.0), 0.0, 1.0), 1.8);
        float thickness2 = 0.18 + h * 0.38;
        float profile2 = exp(-d2 * d2 / (thickness2 * thickness2));
        float curtainAlpha2 = profile2 * (1.0 - h * 0.45) * (0.3 + 0.7 * foldPattern2) * 0.55;

        // Altitude color blending
        vec3 layerCol = mix(cEmerald, cCyan, smoothstep(0.08, 0.42, h));
        layerCol = mix(layerCol, cViolet, smoothstep(0.38, 0.75, h));
        layerCol = mix(layerCol, cCrimson, smoothstep(0.70, 0.98, h));

        auroraAccum += layerCol * (curtainAlpha1 + curtainAlpha2) * 0.25;
    }

    auroraAccum += diffuseCol * diffuseGlow;

    return auroraAccum * horizonFade * zenithFade * northMask * weatherFade * AURORA_BRIGHTNESS;
}
