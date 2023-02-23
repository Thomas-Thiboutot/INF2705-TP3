#version 410

/////////////////////////////////////////////////////////////////

layout(location=0) in vec4 Vertex;
layout(location=8) in vec4 TexCoord;

out Attribs {
    vec2 texCoord;
} AttribsOut;

void main( void )
{
    gl_Position = Vertex;
    AttribsOut.texCoord = TexCoord.st;
}
