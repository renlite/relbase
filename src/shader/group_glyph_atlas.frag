#version 110

/* scaled */
uniform vec2 frame_size; //window_size not used here

// for Texture
//uniform sampler2D textures[32];

uniform sampler2D glyp_atlas_texture;

varying vec2 fragTexCoord;

void main() {
    // float maskR = texture2D(glyp_atlas_texture, fragTexCoord).r;
    gl_FragColor = texture2D(glyp_atlas_texture, fragTexCoord);
    // gl_FragColor = vec4(1.0, 0.5, 0.0, 1.0);
}


