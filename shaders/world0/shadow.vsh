#version 120
#include "/lib/settings.glsl"
#ifdef IS_LPV_ENABLED
	#extension GL_ARB_explicit_attrib_location: enable
	#extension GL_ARB_shader_image_load_store: enable
	#extension GL_ARB_shading_language_packing : enable
#endif

#define RENDER_SHADOW


/*
!! DO NOT REMOVE !!
This code is from Chocapic13' shaders
Read the terms of modification and sharing before changing something below please !
!! DO NOT REMOVE !!
*/

#define SHADOW_MAP_BIAS 0.5
const float PI = 3.1415927;
varying vec2 texcoord;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform int hideGUI;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int frameCounter;
uniform float screenBrightness;
uniform vec3 sunVec;
uniform float aspectRatio;
uniform float sunElevation;
uniform vec3 sunPosition;
uniform float lightSign;
uniform float cosFov;
uniform vec3 shadowViewDir;
uniform vec3 shadowCamera;
uniform vec3 shadowLightVec;
uniform float shadowMaxProj;
attribute vec4 mc_midTexCoord;
varying vec4 color;

attribute vec4 mc_Entity;
uniform int blockEntityId;
uniform int entityId;

#include "/lib/Shadow_Params.glsl"
#include "/lib/bokeh.glsl"
#include "/lib/blocks.glsl"
#include "/lib/entities.glsl"

#ifdef IS_LPV_ENABLED
	#ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
		attribute vec4 at_midBlock;
	#else
		attribute vec3 at_midBlock;
	#endif

	#ifdef LPV_ENTITY_LIGHTS
		uniform usampler1D texBlockData;
	#endif
	
    uniform int currentRenderedItemId;
	uniform int renderStage;
uniform float rainStrength;

	#include "/lib/voxel_common.glsl"
	#include "/lib/voxel_write.glsl"
#endif

const float PI48 = 150.796447372*WAVY_SPEED;
float pi2wt = PI48*frameTimeCounter;

// Dynamic Weather Wind Simulation for Shadows of Plants & Leaves
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

    return vec3(xzOffset.x, yOffset, xzOffset.y) * (1.0 / 255.0);
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

    // Macro cluster sway
    float branchWave = sin(windCoord * 0.18 - frameTimeCounter * 2.0 * WAVY_SPEED * weatherSpeed + pos.y * 0.20);
    vec3 branchOffset = vec3(windDir.x, -0.30, windDir.y) * (branchWave * 0.22);

    // Micro leaf fluttering & trembling
    vec3 leafFlutter = sin(pos * 3.5 + vec3(frameTimeCounter * 5.5, frameTimeCounter * 6.8, frameTimeCounter * 5.0) * WAVY_SPEED * weatherSpeed);

    // Storm turbulent gusts
    float stormGust = sin(windCoord * 0.75 - frameTimeCounter * 9.2 * WAVY_SPEED) * stormFactor;
    vec3 stormTurbulence = vec3(stormGust * 0.12, -abs(stormGust) * 0.08, stormGust * 0.09);

    vec3 totalLeafMove = (branchOffset + leafFlutter * 0.065 + stormTurbulence) * weatherMult * WAVY_STRENGTH;
    return totalLeafMove * (1.0 / 255.0);
}

vec3 calcMoveLeaves(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    return calcMoveLeaves(pos);
}
bool intersectCone(float coneHalfAngle, vec3 coneTip , vec3 coneAxis, vec3 rayOrig, vec3 rayDir, float maxZ)
{
  vec3 co = rayOrig - coneTip;
  float prod = dot(normalize(co),coneAxis);
  if (prod <= -coneHalfAngle) return true;   //In view frustrum

  float a = dot(rayDir,coneAxis)*dot(rayDir,coneAxis) - coneHalfAngle*coneHalfAngle;
  float b = 2. * (dot(rayDir,coneAxis)*dot(co,coneAxis) - dot(rayDir,co)*coneHalfAngle*coneHalfAngle);
  float c = dot(co,coneAxis)*dot(co,coneAxis) - dot(co,co)*coneHalfAngle*coneHalfAngle;

  float det = b*b - 4.*a*c;
  if (det < 0.) return false;    // No intersection with either forward cone and backward cone

  det = sqrt(det);
  float t2 = (-b + det) / (2. * a);
  if (t2 <= 0.0 || t2 >= maxZ) return false;  //Idk why it works

  return true;
}
#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)



// uniform float far;
uniform float dhFarPlane;

#include "/lib/DistantHorizons_projections.glsl"

vec4 toClipSpace3(vec3 viewSpacePosition) {

	// mat4 projection = DH_shadowProjectionTweak(gl_ProjectionMatrix);

    return vec4(projMAD(gl_ProjectionMatrix, viewSpacePosition),1.0);
}
vec3 viewToWorld(vec3 viewPos) {
    vec4 pos;
    pos.xyz = viewPos;
    pos.w = 0.0;
    pos = shadowModelViewInverse * pos;
    return pos.xyz;
}

// uniform int renderStage;
uniform float rainStrength;

// uniform mat4 gbufferModelViewInverse;
void main() {
	if (uint(gl_VertexID) >= 0x20000000u) {
		gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
		return;
	}
	texcoord.xy = gl_MultiTexCoord0.xy;
	color = gl_Color;

	vec3 position = mat3(gl_ModelViewMatrix) * vec3(gl_Vertex) + gl_ModelViewMatrix[3].xyz;
	// playerpos = vec4(0.0);
	// playerpos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);
	
	// mat4 Custom_ViewMatrix = BuildShadowViewMatrix(LightDir);
	// mat4 Custom_ProjectionMatrix = BuildShadowProjectionMatrix();

	// position = gl_Vertex.xyz;

	// if((renderStage == 10 || renderStage == 12) && mc_Entity.x != 3000) {
	// 	position = (shadowModelViewInverse * vec4(gl_Vertex.xyz,1.0)).xyz;
	// } 
	
	// position = mat3(Custom_ViewMatrix) * position + Custom_ViewMatrix[3].xyz;

	// HHHHHHHHH ITS THE JITTER DOF HERE TO SAY HELLO
	// It turns out 'position' above is just viewPos lmao
	// #ifdef DOF_JITTER_SHADOW
	// 	// CLIP SPACE
	// 	vec2 jitter = clamp(jitter_offsets[frameCounter % 64], -1.0, 1.0);
	// 	jitter = rotate(radians(float(frameCounter))) * jitter;
	// 	jitter.y *= aspectRatio;
	// 	jitter.x *= DOF_ANAMORPHIC_RATIO;

	// 	vec4 clipPos = gbufferProjection * vec4(position, 1.0);

	// 	// CLIP SPACE -> VIEW SPACE
	// 	vec3 viewPos = (gbufferProjectionInverse * clipPos).xyz;

	// 	// Focus distance
	// 	#if DOF_JITTER_FOCUS < 0
	// 	float focusMul = clipPos.z - mix(pow(512.0, screenBrightness), 512.0 * screenBrightness, 0.25);
	// 	#else
	// 	float focusMul = clipPos.z - DOF_JITTER_FOCUS;
	// 	#endif

	// 	// CLIP SPACE -> SHADOW CLIP SPACE
	// 	vec3 jitterViewPos = (gbufferProjectionInverse * vec4(jitter, 1.0, 1.0)).xyz;
	// 	// vec3 jitterFeetPos = (gbufferModelViewInverse * vec4(jitterViewPos, 1.0)).xyz;
	// 	// vec3 jitterShadowViewPos = (shadowModelView * vec4(jitterFeetPos, 1.0)).xyz;
	// 	// vec4 jitterShadowClipPos = gl_ProjectionMatrix * vec4(jitterShadowViewPos, 1.0);
		
	// 	// vec4 totalOffset = jitterShadowClipPos * JITTER_STRENGTH * focusMul * 1e-2;

	// 	position += jitterViewPos * focusMul * 1e-2;
	// 	if(focusMul < 10.0) {
	// 		gl_Position = vec4(-1.0);
	// 		return;
	// 	}
	// #endif

	#if defined IS_LPV_ENABLED || defined WAVY_PLANTS
		vec3 playerpos = mat3(shadowModelViewInverse) * position + shadowModelViewInverse[3].xyz;
	#endif

	#if defined IS_LPV_ENABLED && defined MC_GL_EXT_shader_image_load_store
		PopulateShadowVoxel(playerpos);
	#endif

	// #ifdef WAVY_PLANTS
  	// 	bool istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t;
  	// 	if (
  	// 		(
  	// 			blockId == BLOCK_GROUND_WAVING || blockId == BLOCK_GROUND_WAVING_VERTICAL ||
  	// 			blockId == BLOCK_GRASS_SHORT || (blockId == BLOCK_GRASS_TALL_UPPER && istopv) ||
  	// 			blockId == BLOCK_SAPLING
	// 		) && length(position.xy) < 24.0
	// 	) {
	// 		playerpos += calcMovePlants(playerpos + cameraPosition)*gl_MultiTexCoord1.y;
	// 		position = mat3(shadowModelView) * playerpos + shadowModelView[3].xyz;
  	// 	}

  	// 	if (blockId == BLOCK_AIR_WAVING && length(position.xy) < 24.0) {
	// 		playerpos += calcMoveLeaves(playerpos + cameraPosition, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5))*gl_MultiTexCoord1.y;
	// 		position = mat3(shadowModelView) * playerpos + shadowModelView[3].xyz;
  	// 	}
	// #endif

	int blockId = int(mc_Entity.x + 0.5);

	#ifdef WAVY_PLANTS
		// also use normal, so up/down facing geometry does not get detatched from its model parts.
		bool InterpolateFromBase = gl_MultiTexCoord0.t < max(mc_midTexCoord.t, abs(viewToWorld(normalize(gl_NormalMatrix * gl_Normal)).y));

		if(	
			(
				// these wave off of the ground. the area connected to the ground does not wave.
				(InterpolateFromBase && (blockId == BLOCK_GRASS_TALL_LOWER || blockId == BLOCK_GROUND_WAVING || blockId == BLOCK_GRASS_SHORT || blockId == BLOCK_SAPLING || blockId == BLOCK_GROUND_WAVING_VERTICAL)) 

				// these wave off of the ceiling. the area connected to the ceiling does not wave.
				|| (!InterpolateFromBase && (blockId == BLOCK_VINE_OTHER))

				// these wave off of the air. they wave uniformly
				|| (blockId == BLOCK_GRASS_TALL_UPPER || blockId == BLOCK_AIR_WAVING)

			) && length(playerpos.xyz) < 144.0
		){
			float distToCam = length(playerpos.xyz);
			float shadowFade = smoothstep(144.0, 100.0, distToCam);
			vec3 worldpos = playerpos;

			// apply displacement for waving plant blocks
			worldpos += calcMovePlants(playerpos + cameraPosition) * (max(gl_MultiTexCoord1.y, 0.5) * shadowFade);

			// apply displacement for waving leaf blocks specifically, overwriting the other waving mode. these wave off of the air. they wave uniformly
			#ifdef WAVY_LEAVES
			if(blockId == BLOCK_AIR_WAVING) worldpos = playerpos + calcMoveLeaves(playerpos + cameraPosition, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0, 0.2, 1.0), vec3(0.5, 0.1, 0.5)) * (max(gl_MultiTexCoord1.y, 160.0) * shadowFade);
#endif
			
			position = mat3(shadowModelView) * worldpos + shadowModelView[3].xyz;
		}
	#endif

	
	#ifdef DISTORT_SHADOWMAP
		if (entityId == ENTITY_SSS_MEDIUM || entityId == ENTITY_SLIME)
			position.xyz = position.xyz - normalize(gl_NormalMatrix * gl_Normal) * 0.25;

		gl_Position = BiasShadowProjection(toClipSpace3(position));
	#else
		gl_Position = toClipSpace3(position);
	#endif
 	

	if (blockId == BLOCK_WATER) gl_Position.w = -1.0;

  	gl_Position.z /= 6.0;
}