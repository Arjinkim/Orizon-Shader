
#include "/lib/settings.glsl"
#include "/lib/res_params.glsl"
#include "/lib/bokeh.glsl"
#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"
#include "/lib/items.glsl"

/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/


#ifdef HAND
#undef POM
#endif

#ifndef USE_LUMINANCE_AS_HEIGHTMAP
#ifndef MC_NORMAL_MAP
#undef POM
#endif
#endif

#ifdef POM
#define MC_NORMAL_MAP
#endif


varying vec4 color;
varying float VanillaAO;

varying vec4 lmtexcoord;
varying vec4 normalMat;

// #ifdef POM
	varying vec4 vtexcoordam; // .st for add, .pq for mul
	varying vec4 vtexcoord;
// #endif

#ifdef MC_NORMAL_MAP
	varying vec4 tangent;
	attribute vec4 at_tangent;
	varying vec3 FlatNormals;
#endif

uniform float frameTimeCounter;
const float PI48 = 150.796447372*WAVY_SPEED;
float pi2wt = PI48*frameTimeCounter;

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform int blockEntityId;
uniform int entityId;
flat varying float blockID;

uniform int heldItemId;
uniform int heldItemId2;
flat varying float HELD_ITEM_BRIGHTNESS;



flat varying int NameTags;

uniform int frameCounter;
uniform float far;
uniform float aspectRatio;
uniform float viewHeight;
uniform float viewWidth;
uniform int hideGUI;
uniform float screenBrightness;
uniform float rainStrength;
uniform float wetness;
uniform int isEyeInWater;

flat varying float SSSAMOUNT;
flat varying float EMISSIVE;
flat varying int LIGHTNING;
flat varying int PORTAL;
flat varying int SIGN;

// in vec3 at_velocity;
// out vec3 velocity;



uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform vec2 texelSize;
uniform int framemod8;

#include "/lib/TAA_jitter.glsl"


							
#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)
vec4 toClipSpace3(vec3 viewSpacePosition) {
    return vec4(projMAD(gl_ProjectionMatrix, viewSpacePosition),-viewSpacePosition.z);
}

// Dynamic Weather Wind Simulation for Plants & Leaves
vec3 calcMovePlants(in vec3 pos) {
    float rainVal = clamp(rainStrength, 0.0, 1.0);
    float rainFactor = smoothstep(0.05, 0.65, rainVal);
    float stormFactor = smoothstep(0.65, 1.0, rainVal);

    float weatherMult = mix(1.0, float(WAVY_RAIN_MULTIPLIER), rainFactor);
    weatherMult = mix(weatherMult, float(WAVY_STORM_MULTIPLIER), stormFactor);

    float weatherSpeed = mix(1.0, 1.55, rainFactor);
    weatherSpeed = mix(weatherSpeed, 2.35, stormFactor);

    const vec2 windDir = vec2(0.85, 0.52);
    float windCoord = dot(pos.xz, windDir);

    float wave1 = sin(windCoord * 0.16 - frameTimeCounter * 2.5 * WAVY_SPEED * weatherSpeed + pos.y * 0.15);
    float wave2 = sin(windCoord * 0.42 + pos.x * 0.2 - frameTimeCounter * 4.6 * WAVY_SPEED * weatherSpeed);
    float flutter = sin(dot(pos, vec3(1.2, 0.9, 1.4)) * 2.2 - frameTimeCounter * 8.5 * WAVY_SPEED * weatherSpeed);

    float plantDisplacement = (wave1 * 0.62 + wave2 * 0.26 + flutter * (0.12 + 0.18 * stormFactor)) * weatherMult;
    vec2 xzOffset = windDir * plantDisplacement * 0.18 * WAVY_STRENGTH;
    float yOffset = -length(xzOffset) * 0.45;

    return vec3(xzOffset.x, yOffset, xzOffset.y);
}

vec3 calcMoveLeaves(in vec3 pos) {
    float rainVal = clamp(rainStrength, 0.0, 1.0);
    float rainFactor = smoothstep(0.05, 0.65, rainVal);
    float stormFactor = smoothstep(0.65, 1.0, rainVal);

    float weatherMult = mix(1.0, float(WAVY_RAIN_MULTIPLIER), rainFactor);
    weatherMult = mix(weatherMult, float(WAVY_STORM_MULTIPLIER), stormFactor);

    float weatherSpeed = mix(1.0, 1.45, rainFactor);
    weatherSpeed = mix(weatherSpeed, 2.25, stormFactor);

    const vec2 windDir = vec2(0.85, 0.52);
    float windCoord = dot(pos.xz, windDir);

    // Macro cluster sway (natural canopy wind sway)
    float branchWave = sin(windCoord * 0.18 - frameTimeCounter * 2.0 * WAVY_SPEED * weatherSpeed + pos.y * 0.20);
    vec3 branchOffset = vec3(windDir.x, -0.30, windDir.y) * (branchWave * 0.22);

    // Micro leaf fluttering & trembling
    vec3 leafFlutter = sin(pos * 3.5 + vec3(frameTimeCounter * 5.5, frameTimeCounter * 6.8, frameTimeCounter * 5.0) * WAVY_SPEED * weatherSpeed);

    // Storm turbulent gusts
    float stormGust = sin(windCoord * 0.75 - frameTimeCounter * 9.2 * WAVY_SPEED) * stormFactor;
    vec3 stormTurbulence = vec3(stormGust * 0.12, -abs(stormGust) * 0.08, stormGust * 0.09);

    vec3 totalLeafMove = (branchOffset + leafFlutter * 0.065 + stormTurbulence) * weatherMult * WAVY_STRENGTH;
    return totalLeafMove;
}

vec3 calcMoveLeaves(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    return calcMoveLeaves(pos);
}
vec3 srgbToLinear2(vec3 srgb){
    return mix(
        srgb / 12.92,
        pow(.947867 * srgb + .0521327, vec3(2.4) ),
        step( .04045, srgb )
    );
}
vec3 blackbody2(float Temp)
{
    float t = pow(Temp, -1.5);
    float lt = log(Temp);

    vec3 col = vec3(0.0);
         col.x = 220000.0 * t + 0.58039215686;
         col.y = 0.39231372549 * lt - 2.44549019608;
         col.y = Temp > 6500. ? 138039.215686 * t + 0.72156862745 : col.y;
         col.z = 0.76078431372 * lt - 5.68078431373;
         col = clamp(col,0.0,1.0);
         col = Temp < 1000. ? col * Temp * 0.001 : col;

    return srgbToLinear2(col);
}
// float luma(vec3 color) {
// 	return dot(color,vec3(0.21, 0.72, 0.07));
// }

#define SEASONS_VSH
#include "/lib/climate_settings.glsl"


uniform sampler2D noisetex;//depth
float densityAtPos(in vec3 pos){
	pos /= 18.;
	pos.xz *= 0.5;
	vec3 p = floor(pos);
	vec3 f = fract(pos);
	vec2 uv =  p.xz + f.xz + p.y * vec2(0.0,193.0);
	vec2 coord =  uv / 512.0;
	
	//The y channel has an offset to avoid using two textures fetches
	vec2 xy = texture2D(noisetex, coord).yx;

	return mix(xy.r,xy.g, f.y);
}
float luma(vec3 color) {
	return dot(color,vec3(0.21, 0.72, 0.07));
}
vec3 viewToWorld(vec3 viewPos) {
    vec4 pos;
    pos.xyz = viewPos;
    pos.w = 0.0;
    pos = gbufferModelViewInverse * pos;
    return pos.xyz;
}
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////


#if defined WORLD && !defined ENTITIES && !defined BLOCKENTITIES && !defined HAND
uvec4 hz_far_corner(uvec3 lo, uvec3 hi, uint corner) {
	uint axis = hi.z & 3u;
	uint reversed = (hi.z >> 2u) & 1u;
	float plane = float(int(lo.z));
	float u0 = float(int(hi.x));
	float v0 = float(int(hi.y));
	float u1 = u0 + float((hi.z >> 3u) & 0x7ffu);
	float v1 = v0 + float((hi.z >> 14u) & 0x7ffu);
	uint c = corner;
	if (reversed == 1u) {
		c = 3u - corner;
	}
	float far_v = v0;
	if (c <= 1u) {
		far_v = v1;
	}
	bool first = (c == 0u || c == 3u);
	float far_u = u1;
	if (axis == 2u) {
		if (!first) {
			far_u = u0;
		}
	} else {
		if (first) {
			far_u = u0;
		}
	}
	vec3 pos = vec3(far_u, plane, far_v);
	if (axis == 1u) {
		pos = vec3(far_u, far_v, plane);
	} else if (axis == 2u) {
		pos = vec3(plane, far_v, far_u);
	}
	uvec2 uv = uvec2(vec2(far_u - u0, v1 - far_v) * 32.0);
	return uvec4(floatBitsToUint(pos), uv.x | (uv.y << 16u));
}

void hz_fix_far_terrain() {
	uint hz_qv = uint(gl_VertexID);
	if (hz_qv < 0x20000000u) {
		return;
	}
	int hz_side0 = 1;
	if (uint(hz_tables[0]) > 1u) {
		if (hz_tables[3] > 1) {
			hz_side0 = hz_tables[3];
		}
	}
	vec2 hz_inv_atlas = hz_scale / float(hz_side0);
	uint hz_own = hz_qv & 3u;
	uint hz_slot = (hz_qv - 0x20000000u) >> 2u;
	uint hz_rw = hz_slot * 6u;
	uvec3 hz_lo = uvec3(hz_vertices[hz_rw], hz_vertices[hz_rw + 1u], hz_vertices[hz_rw + 2u]);
	uvec3 hz_hi = uvec3(hz_vertices[hz_rw + 3u], hz_vertices[hz_rw + 4u], hz_vertices[hz_rw + 5u]);
	bool hz_rec = (hz_hi.z & 0x80000000u) == 0u;
	uint hz_av = hz_slot + hz_lo.x;
	uvec3 hz_cp0; uvec3 hz_cp1; uvec3 hz_cp2; uvec3 hz_cp3;
	uint hz_uv0; uint hz_uv1; uint hz_uv2; uint hz_uv3;
	uvec2 hz_rest;
	if (hz_rec) {
		uvec4 fc0 = hz_far_corner(hz_lo, hz_hi, 0u);
		uvec4 fc1 = hz_far_corner(hz_lo, hz_hi, 1u);
		uvec4 fc2 = hz_far_corner(hz_lo, hz_hi, 2u);
		uvec4 fc3 = hz_far_corner(hz_lo, hz_hi, 3u);
		hz_cp0 = fc0.xyz; hz_uv0 = fc0.w;
		hz_cp1 = fc1.xyz; hz_uv1 = fc1.w;
		hz_cp2 = fc2.xyz; hz_uv2 = fc2.w;
		hz_cp3 = fc3.xyz; hz_uv3 = fc3.w;
		hz_rest = uvec2(hz_lo.y, hz_lo.x);
	} else {
		hz_arena_corner(hz_av, hz_cp0, hz_uv0);
		hz_arena_corner(hz_av + 1u, hz_cp1, hz_uv1);
		hz_arena_corner(hz_av + 2u, hz_cp2, hz_uv2);
		hz_arena_corner(hz_av + 3u, hz_cp3, hz_uv3);
		uint hz_ow = (hz_av + hz_own) * 6u;
		hz_rest = uvec2(hz_vertices[hz_ow + 4u], hz_vertices[hz_ow + 5u]);
	}
	uvec3 hz_vp = hz_cp3;
	uint hz_vuv = hz_uv3;
	if (hz_own == 0u) {
		hz_vp = hz_cp0;
		hz_vuv = hz_uv0;
	} else if (hz_own == 1u) {
		hz_vp = hz_cp1;
		hz_vuv = hz_uv1;
	} else if (hz_own == 2u) {
		hz_vp = hz_cp2;
		hz_vuv = hz_uv2;
	}
	uvec3 hz_vr = uvec3(hz_vuv, hz_rest);
	hz_v_pos = uintBitsToFloat(hz_vp);
	hz_v_uv = uvec2(hz_vr.x & 65535u, hz_vr.x >> 16u);
	hz_v_layer = hz_vr.y & 65535u;
	hz_v_light = uvec2((hz_vr.y >> 16u) & 255u, hz_vr.y >> 24u);
	hz_v_color = vec4(float(hz_vr.z & 255u), float((hz_vr.z >> 8u) & 255u), float((hz_vr.z >> 16u) & 255u), float(hz_vr.z >> 24u)) * (1.0 / 255.0);

	vec4 hz_origin = hz_slot_origins[hz_block_slots[hz_slot >> 8u]];
	uint hz_layer = hz_v_layer & 32767u;
	uvec2 hz_rect = uvec2(0u, 1u);
	if (2u * hz_layer + 1u < uint(hz_tables[0])) {
		hz_rect = uvec2(uint(hz_tables[2u + 2u * hz_layer]), uint(hz_tables[3u + 2u * hz_layer]));
	}
	hz_cell = vec2(float(hz_rect.x & 65535u), float(hz_rect.x >> 16u)) / float(max(hz_rect.y, 1u));
	hz_scale = hz_inv_atlas * float(hz_rect.y);
	gl_Vertex = vec4(floor(hz_v_pos * 32768.0 + 0.03125) / 32768.0 + hz_origin.xyz, 1.0);
	if (hz_origin.w > 0.0) {
		hz_uv_scale = uintBitsToFloat(floatBitsToUint(hz_origin.w) & 0xff800000u);
	} else {
		hz_uv_scale = fract(abs(hz_origin.w));
	}
	hz_mid = vec2(0.5);
	gl_MultiTexCoord0 = vec4((hz_cell + clamp(vec2(hz_v_uv) * hz_uv_scale, 0.0, 1.0)) * hz_scale, 0.0, 1.0);
	gl_MultiTexCoord1 = vec4(float(hz_v_light.y), float(hz_v_light.x), 0.0, 1.0);
	gl_Color = vec4(hz_v_color.rgb, 1.0);
	gl_Normal = vec3(0.0, 1.0, 0.0);
	hz_tangent = vec4(1.0, 0.0, 0.0, 1.0);

	vec3 hz_p0 = uintBitsToFloat(hz_cp0);
	vec3 hz_p1 = uintBitsToFloat(hz_cp1);
	vec3 hz_p2 = uintBitsToFloat(hz_cp2);
	vec3 hz_e1 = hz_p1 - hz_p0;
	vec3 hz_e2 = hz_p2 - hz_p0;
	vec3 hz_n = cross(hz_e1, hz_e2);
	if (dot(hz_n, hz_n) > 1e-12) {
		gl_Normal = normalize(hz_n);
	}
	#ifdef MC_NORMAL_MAP
	at_tangent = hz_tangent;
	#endif
	mc_midTexCoord = vec4((hz_cell + hz_mid) * hz_scale, 0.0, 1.0);
	mc_Entity = vec4(-1.0, 0.0, 0.0, 0.0);
}
#endif

void main() {
	#if defined WORLD && !defined ENTITIES && !defined BLOCKENTITIES && !defined HAND
		hz_fix_far_terrain();
	#endif

	gl_Position = ftransform();

	vec3 position = mat3(gl_ModelViewMatrix) * vec3(gl_Vertex) + gl_ModelViewMatrix[3].xyz;

    /////// ----- COLOR STUFF ----- ///////
	color = gl_Color;

	VanillaAO = 1.0 - clamp(color.a,0,1);
	if (color.a < 0.3) color.a = 1.0; // fix vanilla ao on some custom block models.

    /////// ----- RANDOM STUFF ----- ///////
	// gl_TextureMatrix[0] for animated things like charged creepers
	lmtexcoord.xy = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	// #ifdef POM
	vec2 midcoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texcoordminusmid = lmtexcoord.xy-midcoord;
	vtexcoordam.pq  = abs(texcoordminusmid)*2;
	vtexcoordam.st  = min(lmtexcoord.xy,midcoord-texcoordminusmid);
	vtexcoord.xy    = sign(texcoordminusmid)*0.5+0.5;
	// #endif


	vec2 lmcoord = gl_MultiTexCoord1.xy / 240.0; 
	lmtexcoord.zw = lmcoord;



	#ifdef MC_NORMAL_MAP
		tangent = vec4(normalize(gl_NormalMatrix * at_tangent.rgb), at_tangent.w);
	#endif

	normalMat = vec4(normalize(gl_NormalMatrix * gl_Normal), 1.0);
	FlatNormals = normalMat.xyz;

	blockID = mc_Entity.x ;

	if(blockID == BLOCK_GROUND_WAVING_VERTICAL || blockID == BLOCK_GRASS_SHORT || blockID == BLOCK_GRASS_TALL_LOWER || blockID == BLOCK_GRASS_TALL_UPPER ) normalMat.a = 0.60;


	PORTAL = 0;
	SIGN = 0;

	#ifdef WORLD
		if(blockEntityId == BLOCK_SIGN) SIGN = 1;

		if(blockEntityId == BLOCK_END_PORTAL) PORTAL = 1;
	#endif
	
	NameTags = 0;

#ifdef ENTITIES
	// disallow POM to work on item frames.
	if(entityId == ENTITY_ITEM_FRAME) SIGN = 1;


	// try and single out nametag text and then discard nametag background
	// if( dot(gl_Color.rgb, vec3(1.0/3.0)) < 1.0) NameTags = 1;
	// if(gl_Color.a < 1.0) NameTags = 1;
	// if(gl_Color.a >= 0.24 && gl_Color.a <= 0.25 ) gl_Position = vec4(10,10,10,1);
	if(entityId == ENTITY_SSS_MEDIUM || entityId == ENTITY_SSS_WEAK || entityId == ENTITY_PLAYER || entityId == 2468) normalMat.a = 0.45;
	
#endif

	if(mc_Entity.x == BLOCK_AIR_WAVING) normalMat.a = 0.55;

    /////// ----- EMISSIVE STUFF ----- ///////
		EMISSIVE = 0.0;
		LIGHTNING = 0;
	// if(NameTags > 0) EMISSIVE = 0.9;

	HELD_ITEM_BRIGHTNESS = 0.0;
	#ifdef Hand_Held_lights
		if(heldItemId > 999 || heldItemId2 > 999 ) HELD_ITEM_BRIGHTNESS = 0.9;
	#endif

	// normal block lightsources		
	if(mc_Entity.x >= 100 && mc_Entity.x < 300) EMISSIVE = 0.5;
	
	// special cases light lightning and beacon beams...	
	#ifdef ENTITIES
		if(entityId == ENTITY_LIGHTNING){
			LIGHTNING = 1;
			normalMat.a = 0.50;
		}
	#endif

    /////// ----- SSS STUFF ----- ///////
		SSSAMOUNT = 0.0;

#ifdef WORLD
    /////// ----- SSS ON BLOCKS ----- ///////
	// strong
	if (
		mc_Entity.x == BLOCK_GROUND_WAVING || mc_Entity.x == BLOCK_GROUND_WAVING_VERTICAL || mc_Entity.x == BLOCK_AIR_WAVING ||
		mc_Entity.x == BLOCK_GRASS_SHORT || mc_Entity.x == BLOCK_GRASS_TALL_UPPER || mc_Entity.x == BLOCK_GRASS_TALL_LOWER ||
		mc_Entity.x == BLOCK_SSS_STRONG || mc_Entity.x == BLOCK_SAPLING
	) {
		SSSAMOUNT = 1.0;
	}

	// medium
	if (
		mc_Entity.x == BLOCK_SSS_WEAK || mc_Entity.x == BLOCK_SSS_WEAK_2 ||
		mc_Entity.x == BLOCK_GLOW_LICHEN || mc_Entity.x == BLOCK_SNOW_LAYERS || mc_Entity.x == BLOCK_CARPET ||
		mc_Entity.x == BLOCK_AMETHYST_BUD_MEDIUM || mc_Entity.x == BLOCK_AMETHYST_BUD_LARGE || mc_Entity.x == BLOCK_AMETHYST_CLUSTER ||
		mc_Entity.x == BLOCK_BAMBOO || mc_Entity.x == BLOCK_SAPLING || mc_Entity.x == BLOCK_VINE
	) {
		SSSAMOUNT = 0.75;
	}
	// low
	#ifdef MISC_BLOCK_SSS
		if(mc_Entity.x == BLOCK_SSS_WEIRD || mc_Entity.x == BLOCK_GRASS) SSSAMOUNT = 0.5; // weird SSS on blocks like grass and stuff
	#endif

	#ifdef ENTITIES
		#ifdef MOB_SSS
		    /////// ----- SSS ON MOBS----- ///////
			// strong
			if(entityId == ENTITY_SSS_MEDIUM) SSSAMOUNT = 0.75;
	
			// medium
	
			// low
			if(entityId == ENTITY_SSS_WEAK || entityId == ENTITY_PLAYER) SSSAMOUNT = 0.4;
		#endif
	#endif

	#ifdef BLOCKENTITIES
	    /////// ----- SSS ON BLOCK ENTITIES----- ///////
		// strong

		// medium
		if(blockEntityId == BLOCK_SSS_WEAK_3) SSSAMOUNT = 0.4;

		// low

	#endif


	#ifdef WAVY_PLANTS
		// also use normal, so up/down facing geometry does not get detatched from its model parts.
		bool InterpolateFromBase = gl_MultiTexCoord0.t < max(mc_midTexCoord.t, abs(viewToWorld(FlatNormals).y));

		if(	
			(
				// these wave off of the ground. the area connected to the ground does not wave.
				(InterpolateFromBase && (mc_Entity.x == BLOCK_GRASS_TALL_LOWER || mc_Entity.x == BLOCK_GROUND_WAVING || mc_Entity.x == BLOCK_GRASS_SHORT || mc_Entity.x == BLOCK_SAPLING || mc_Entity.x == BLOCK_GROUND_WAVING_VERTICAL)) 

				// these wave off of the ceiling. the area connected to the ceiling does not wave.
				|| (!InterpolateFromBase && (mc_Entity.x == 17))

				// these wave off of the air. they wave uniformly
				|| (mc_Entity.x == BLOCK_GRASS_TALL_UPPER || mc_Entity.x == BLOCK_AIR_WAVING)

			) && length(position.xyz) < 240.0
		){
			float distToCam = length(position.xyz);
			float distanceFade = smoothstep(240.0, 160.0, distToCam);

   			vec3 worldpos = mat3(gbufferModelViewInverse) * position + gbufferModelViewInverse[3].xyz;
			vec3 UnalteredWorldpos = worldpos;

			// apply displacement for waving plant blocks
			worldpos += calcMovePlants(worldpos + cameraPosition) * (max(lmtexcoord.w, 0.5) * distanceFade);

			// apply displacement for waving leaf blocks specifically, overwriting the other waving mode. these wave off of the air. they wave uniformly
			#ifdef WAVY_LEAVES
			if(mc_Entity.x == BLOCK_AIR_WAVING) worldpos = UnalteredWorldpos + calcMoveLeaves(worldpos + cameraPosition, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5)) * (max(lmtexcoord.w, 0.65) * distanceFade);
#endif
		
			position = mat3(gbufferModelView) * worldpos + gbufferModelView[3].xyz;
		}
	#endif

	gl_Position = toClipSpace3(position);
#endif

	#if defined Seasons && defined WORLD && !defined ENTITIES && !defined BLOCKENTITIES && !defined HAND
		YearCycleColor(color.rgb, gl_Color.rgb, mc_Entity.x == BLOCK_AIR_WAVING, true);
	#endif

	#ifdef TAA_UPSCALING
		gl_Position.xy = gl_Position.xy * RENDER_SCALE + RENDER_SCALE * gl_Position.w - gl_Position.w;
	#endif
	#ifdef TAA
		gl_Position.xy += offsets[framemod8] * gl_Position.w*texelSize;
	#endif


#if DOF_QUALITY == 5
		vec2 jitter = clamp(jitter_offsets[frameCounter % 64], -1.0, 1.0);
		jitter = rotate(radians(float(frameCounter))) * jitter;
		jitter.y *= aspectRatio;
		jitter.x *= DOF_ANAMORPHIC_RATIO;

		#if MANUAL_FOCUS == -2
		float focusMul = 0;
		#elif MANUAL_FOCUS == -1
		float focusMul = gl_Position.z - mix(pow(512.0, screenBrightness), 512.0 * screenBrightness, 0.25);
		#else
		float focusMul = gl_Position.z - MANUAL_FOCUS;
		#endif

		vec2 totalOffset = (jitter * JITTER_STRENGTH) * focusMul * 1e-2;
		gl_Position.xy += hideGUI >= 1 ? totalOffset : vec2(0);
	#endif
}
