#version 430

layout(location = 0) uniform ivec2 windowSize;
layout(location = 1) uniform int time;


out vec4 fragColor;

const float ktime = 0.00005;
const vec3 waterColor = vec3(0.03, 0.42, 0.81);
const vec3 bottomColor= vec3(0.02, 0.18, 0.32);

const vec3 sunColor = vec3(0.9, 0.7, 0.1);
const float sunRadius = 0.1;
const float sunLightRadius = 0.20;
/*
float rand(float n){return fract(sin(n) * 43758.5453123);}

float SmootherStep(float x)
{
	return (x * x * x* (x * (6 * x - 15) + 10));
}

float noise(float p){
	float fl = floor(p);
  float fc = fract(p);
	return mix(rand(fl), rand(fl + 1.0), SmootherStep(fc));
}
*/
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

	vec2 sunPos = vec2(0.5, 0.7);
	vec2 uv = vec2(gl_FragCoord.xy) / windowSize;
	vec3 color = vec3(0,0,0);
	float waterLevel = PerlinNoise_2D(uv.x, time * ktime, 0.01, 10.0, 3);
	float d = distance((uv * windowSize)/windowSize.y, sunPos); 
	if (uv.y + waterLevel < 0.3)
	{
		color = mix(waterColor, bottomColor, uv.y / 0.3);
		//color = mix(sunColor, color, d);
	}
	else
	{
		float sunWaves = PerlinNoise_2D(uv.x, time * ktime, 0.005, 100.0, 2);
		
		if(d < sunRadius + sunWaves){
			color = sunColor;
		}
		else
		{
			color = vec3((1.3 - uv.y) * 0.5 , (1.3 - uv.y)*0.7, 1);
			if(d < sunLightRadius + sunWaves){
				color = mix(sunColor, color, d / sunLightRadius);
			}
		}
		
	}
	
	
	fragColor = vec4(color, 1.0);
}