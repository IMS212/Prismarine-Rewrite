vec2 dofOffsets[8] = vec2[8](
	vec2( 0.0    ,  0.25  ),
	vec2(-0.2165 ,  0.125 ),
	vec2(-0.2165 , -0.125 ),
	vec2( 0      , -0.25  ),
	vec2( 0.2165 , -0.125 ),
	vec2( 0.2165 ,  0.125 ),
	vec2( 0      ,  0.5   ),
	vec2(-0.25   ,  0.433 )
);

vec3 BoxBlur(sampler2D colortex, float strength, vec2 coord) {
	vec3 blur = vec3(0.0);

	for(int j = 0; j <= 8; j++){
		vec2 offset = dofOffsets[j] * strength * 2.0 * vec2(1.0 / aspectRatio, 1.0);
		blur += texture2D(colortex, coord + offset).rgb;
	}

	return blur / 8.0;
}