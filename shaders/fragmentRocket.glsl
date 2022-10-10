#version 430

layout(location = 0) uniform ivec2 windowSize;
layout(location = 1) uniform int time;
layout(location = 2) uniform vec2 camPos;
layout(location = 3) uniform vec2 camSize;
layout(location = 4) uniform vec2 projVel;


out vec4 fragColor;

const float ktime = 0.005;
const vec3 rocketColor = vec3(0.85, 0.21, 0.21);
const vec3 rocketBottomColor = vec3(0.85, 0.85, 0.85);
const vec2 rocketSize = vec2(1.3, 1.3);
const vec3 fireColor = vec3(0.85, 0.65, 0.1);
const vec3 SecFireColor = vec3(0.85, 0.89, 0.1);

float rand(vec2 n) { 
	return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
	const vec2 d = vec2(0.0, 1.0);
	vec2 b = floor(n); 
	vec2 f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
	return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float PerlinNoise_2D(float x, float y, float ampl, float freq, int n)
{
	float total = 0;
	float p = ampl / (n * (n + 1)/2);
	float frequency = freq;
	for(int i = 0; i < n; i++)
	{
		float amplitude = p * float(i + 1);
		vec2 c = vec2(x, y) * frequency;
		total = total + noise(c) * amplitude;
		frequency = frequency * 2;
	}	
	return total;
}

void main()
{
	vec3 color = vec3(0);
	vec2 uv = gl_FragCoord.xy * camSize - windowSize / 2;
	vec2 normVel =  - normalize(projVel);
	vec2 uv1 = vec2(uv.x * normVel.y - uv.y * normVel.x, uv.x * normVel.x + uv.y * normVel.y) / rocketSize;
	//float waterLevel = PerlinNoise_2D(uv.x, time * ktime, 10.0, 0.01, 5);
	if ((uv1.y < 5 + cos(uv1.x * 3)) && (uv1.x * uv1.x < uv1.y + 5))
	{
		color = mix(rocketColor, rocketBottomColor, uv1.y);
	}
	else
	{
		if ((uv1.y < 13 + PerlinNoise_2D(uv1.x, time * ktime, 5.0, 1.0, 2)) && ((uv1.x) * (uv1.x) + 9 < uv1.y + 5))
		{
			color = mix(fireColor, SecFireColor, PerlinNoise_2D(uv1.y, time * ktime, 1.0, 0.5, 2));	
		}
		else
		{
			discard;
		}
	}	
	fragColor = vec4(color, 1.0);
}