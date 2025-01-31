/* 
BSL Shaders v8 Series by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

varying vec3 upVec, sunVec;

varying vec4 color;

//Uniforms//
#if defined WEATHER_PERBIOME || defined PERBIOME_CLOUDS_COLOR || FOG_COLOR_MODE == 2 || SKY_COLOR_MODE == 1
uniform float isDesert, isMesa, isCold, isSwamp, isMushroom, isSavanna, isForest, isTaiga, isJungle;
#endif

uniform float nightVision;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;
uniform sampler2D gaux1;

#ifdef END
uniform float frameTimeCounter;
uniform int frameCounter, worldTime;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color, vec3(0.299, 0.587, 0.114));
}

//Includes//
#include "/lib/prismarine/timeCalculations.glsl"

#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#endif

#if defined END
#include "/lib/color/endColor.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/clouds.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord);
	vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OVERWORLD
	albedo *= color;
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SKYBOX_BRIGHTNESS * albedo.a;

	#ifdef SKY_DESATURATION
    vec3 desat = GetLuminance(albedo.rgb) * pow(lightNight,vec3(1.6)) * 4.0;
	albedo.rgb = mix(desat, albedo.rgb, sunVisibility);
	#endif
	#endif

	#ifdef END
	albedo.rgb = albedo.rgb *= 0.5 * endCol.rgb;
	albedo.rgb = GetLuminance(albedo.rgb) * albedo.rgb;

	#ifdef END_STARS
	#ifdef SMALL_STARS
	DrawStars(albedo.rgb, viewPos.xyz);
	#endif
	#ifdef BIG_STARS
	DrawBigStars(albedo.rgb, viewPos.xyz);
	#endif
	#endif

	#if END_SKY == 1
	float dither = Bayer64(gl_FragCoord.xy);
	albedo.rgb += DrawRift(viewPos.xyz, dither, 4, 1);
	albedo.rgb += DrawRift(viewPos.xyz, dither, 4, 0);
	#endif

	albedo.rgb *= SKYBOX_BRIGHTNESS * 0.2;
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

varying vec4 color;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

#ifdef TAA
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;
	
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	
	gl_Position = ftransform();
	
	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif