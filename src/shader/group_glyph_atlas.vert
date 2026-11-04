#version 110

/** scaled **/
uniform vec2 frame_size; //window_size

// triangle 6 points (x | y) for rect
attribute vec2 att_vert;
attribute vec4 att_type;    // (texture x | texture y | UNUSED | UNUSED )
// ----- attributes size = 6 ----- 

// for Texture
varying vec2 fragTexCoord;

void main() {
    // normalize att_vert in GPU
    gl_Position = vec4(-1.0 + att_vert.x*2.0/frame_size.x, 1.0 - att_vert.y*2.0/frame_size.y, 0, 1);
    fragTexCoord.x = att_type[0];
    fragTexCoord.y = att_type[1];
}


