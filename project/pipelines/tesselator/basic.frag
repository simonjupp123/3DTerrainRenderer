#version 410 core

in vec2 Tex3;
in float Height;

out vec4 FragColor;
//layout(location = 0) out vec4 FragColor;

uniform sampler2D sampler1;
uniform sampler2D sampler2;
uniform sampler2D sampler3;
uniform sampler2D sampler4;
uniform sampler2D gHeightMap;


uniform float gHeight0 = -8;
uniform float gHeight1 = -5;
uniform float gHeight2 = 3;
uniform float gHeight3 = 8;

uniform vec3 lightDir = vec3(-1,1,-1);

uniform float gColorTexcoordScaling = 16.0;





vec3 GetColor(){
	vec3 color;

	vec2 ScaledTexCoord = Tex3 * gColorTexcoordScaling;

	if (Height < gHeight0) {
		color = texture(sampler1, ScaledTexCoord).rgb;
	} else if (Height < gHeight1) {
		vec3 Color0 = texture(sampler1, ScaledTexCoord).rgb;
		vec3 Color1 = texture(sampler2, ScaledTexCoord).rgb;
		float Delta = gHeight1 - gHeight0;
		float Factor = (Height - gHeight0) / Delta;
		color = mix(Color0, Color1, Factor);
	} else if (Height < gHeight2) {
		vec3 Color0 = texture(sampler2, ScaledTexCoord).rgb;
		vec3 Color1 = texture(sampler3, ScaledTexCoord).rgb;
		float Delta = gHeight2 - gHeight1;
		float Factor = (Height - gHeight1) / Delta;
		color = mix(Color0, Color1, Factor);
	} else if (Height < gHeight3) {
		vec3 Color0 = texture(sampler3, ScaledTexCoord).rgb;
		vec3 Color1 = texture(sampler4, ScaledTexCoord).rgb;
		float Delta = gHeight3 - gHeight2;
		float Factor = (Height - gHeight2) / Delta;
		color = mix(Color0, Color1, Factor);
	} else {
		color = texture(sampler4, ScaledTexCoord).rgb;
	}

	
	return color;
}

vec3 CalcNormal()
{   
    float left  = textureOffset(gHeightMap, Tex3, ivec2(-1, 0)).r;
    float right = textureOffset(gHeightMap, Tex3, ivec2( 1, 0)).r;
    float up    = textureOffset(gHeightMap, Tex3, ivec2( 0, 1)).r;
    float down  = textureOffset(gHeightMap, Tex3, ivec2( 0, -1)).r;

    vec3 normal = normalize(vec3(left - right, 2.0, up - down));
    
    return normal;
}


void main()
{
    vec3 TexColor = GetColor();

    vec3 Normal = CalcNormal();

    float Diffuse = dot(Normal, lightDir);

    Diffuse = max(0.4f, Diffuse);

    FragColor = vec4(TexColor * Diffuse,1.0);
 }