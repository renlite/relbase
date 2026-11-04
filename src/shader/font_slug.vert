#version 110

// ===================================================
// Slug algorithm — GLSL port of the reference shaders.
// Based on Eric Lengyel's public-domain reference code.
// ===================================================

// ─── Uniforms ────────────────────────────────────────

struct Uniforms {
    mat4 mvp;
    vec2 viewport;
    float _pad0;
    float _pad1;
};

uniform Uniforms uniforms;

// ─── Textures ────────────────────────────────────────

// uniforms for fragment -> move down to fragment
// @group(1) @binding(0) var curve_texture: texture_2d<f32>;
uniform float curve_texture;
// @group(1) @binding(1) var band_texture: texture_2d<u32>;
uniform uint band_texture;

// ─── Constants ───────────────────────────────────────

// const K_LOG_BAND_TEXTURE_WIDTH: u32 = 12u;
const uint K_LOG_BAND_TEXTURE_WIDTH = 12u;
// const K_BAND_TEXTURE_WIDTH: i32 = 4096;
const int K_BAND_TEXTURE_WIDTH = 4096;

// ─── Global var ──────────────────────────────────────
// vec2 vpos;
// vec4 vbnd;
// vec4 vgly;

// ─── Vertex I/O ──────────────────────────────────────

/*
struct VertexInput {
    @location(0) pos: vec4<f32>,       // xy = position, zw = normal
    @location(1) tex: vec4<f32>,       // xy = em-space coords, zw = packed integers
    @location(2) jac: vec4<f32>,       // inverse Jacobian (00, 01, 10, 11)
    @location(3) bnd: vec4<f32>,       // band scale x, band scale y, band offset x, band offset y
    @location(4) col: vec4<f32>,       // vertex color RGBA
};
*/
attribute vec4 pos;       // xy = position, zw = normal
attribute vec4 tex;       // xy = em-space coords, zw = packed integers
attribute vec4 jac;       // inverse Jacobian (00, 01, 10, 11)
attribute vec4 bnd;       // band scale x, band scale y, band offset x, band offset y
attribute vec4 col;       // vertex color RGBA

/*
struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) color: vec4<f32>,
    @location(1) texcoord: vec2<f32>,
    @location(2) @interpolate(flat) banding: vec4<f32>,
    @location(3) @interpolate(flat) glyph: vec4<i32>,
};
*/
varying vec4 color;
varying vec2 texcoord;
varying vec4 banding;
varying vec4 glyph;

// ─── Vertex shader ───────────────────────────────────

vec2 slug_unpack(vec4 tex, vec4 bnd, out vec4 vbnd, out int4 vgly) {
    let g = vec2<u32>(bitcast<u32>(tex.z), bitcast<u32>(tex.w));
    /*
    vgly = vec4<i32>(
        i32(g.x & 0xFFFFu),
        i32(g.x >> 16u),
        i32(g.y & 0xFFFFu),
        i32(g.y >> 16u),
    );
    */
    vgly = int4(g.x & 0xFFFFU, g.x >> 16U, g.y & 0xFFFFU, g.y >> 16U);
    vbnd = bnd;
}

vec2 slug_dilate(
    vec4 pos,
    vec4 tex,
    vec4 jac,
    vec4 m0,
    vec4 m1,
    vec4 m3,
    vec2 dim,
    out vec2 vpos
) {
    vec2  n = normalize(pos.zw);
    float s = dot(m3.xy, pos.xy) + m3.w;
    float t = dot(m3.xy, n);

    float u_val = (s * dot(m0.xy, n) - t * (dot(m0.xy, pos.xy) + m0.w)) * dim.x;
    float v_val = (s * dot(m1.xy, n) - t * (dot(m1.xy, pos.xy) + m1.w)) * dim.y;

    float s2 = s * s;
    float st = s * t;
    float uv = u_val * u_val + v_val * v_val;
    vec2  d = pos.zw * (s2 * (st + sqrt(uv)) / (uv - st * st));

    vpos = pos.xy + d;
    vec2 result = (tex.x + dot(d, jac.xy), tex.y + dot(d, jac.zw));
    return result;
}

// @vertex
// fn vs_main(input: VertexInput) -> VertexOutput {
void main() {
    // var out: VertexOutput;
    // = gl_Position
    // var p: vec2<f32>;
    vec2 p;

    // Dynamic dilation
    texcoord = slug_dilate(
        pos, tex, jac,
        uniforms.mvp[0], uniforms.mvp[1], uniforms.mvp[3],
        uniforms.viewport.xy,
        p,
    );

    // Apply MVP to dilated position
    /*
    out.position = vec4<f32>(
        p.x * uniforms.mvp[0].x + p.y * uniforms.mvp[0].y + uniforms.mvp[0].w,
        p.x * uniforms.mvp[1].x + p.y * uniforms.mvp[1].y + uniforms.mvp[1].w,
        p.x * uniforms.mvp[2].x + p.y * uniforms.mvp[2].y + uniforms.mvp[2].w,
        p.x * uniforms.mvp[3].x + p.y * uniforms.mvp[3].y + uniforms.mvp[3].w,
    );
    */
    gl_Position = vec4(
        p.x * uniforms.mvp[0].x + p.y * uniforms.mvp[0].y + uniforms.mvp[0].w,
        p.x * uniforms.mvp[1].x + p.y * uniforms.mvp[1].y + uniforms.mvp[1].w,
        p.x * uniforms.mvp[2].x + p.y * uniforms.mvp[2].y + uniforms.mvp[2].w,
        p.x * uniforms.mvp[3].x + p.y * uniforms.mvp[3].y + uniforms.mvp[3].w,
    );


    // Unpack glyph/band data
    //var vbnd: vec4<f32>;
    vec4 vbnd;
    //var vgly: vec4<i32>;
    vec4 vgly;
    slug_unpack(tex, bnd, vbnd, vgly);
    banding = vbnd;
    glyph = vgly;
    color = col;
}
