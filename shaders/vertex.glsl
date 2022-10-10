#version 430

in vec4 pos;

void main()
{
	gl_Position = vec4(pos.xyz, pos.w);
}