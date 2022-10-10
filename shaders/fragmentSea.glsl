#version 430

layout(location = 0) uniform ivec2 windowSize;
layout(location = 1) uniform int time;
layout(location = 2) uniform vec2 camPos;
layout(location = 3) uniform vec2 camSize;


out vec4 fragColor;

const float ktime = 0.01;
const vec3 waterColor = vec3(0.03, 0.42, 0.81);
const vec3 bottomColor= vec3(0.02, 0.18, 0.32);

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
	vec2 uv = gl_FragCoord.xy * camSize + camPos * 2 - windowSize / 2;
	float waterLevel = PerlinNoise_2D(uv.x, time * ktime, 10.0, 0.01, 5);
	if (uv.y + waterLevel < 5)
	{
		vec3 color = mix(waterColor, bottomColor, abs(uv.y) / windowSize.y * 4);
		fragColor = vec4(color, 1.0);
	}
	else
	{
		discard;
	}	
}