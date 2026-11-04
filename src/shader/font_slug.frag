#version 110

// ─── Constants ───────────────────────────────────────
// const K_LOG_BAND_TEXTURE_WIDTH: u32 = 12u;
const uint K_LOG_BAND_TEXTURE_WIDTH = 12u;
// const K_BAND_TEXTURE_WIDTH: i32 = 4096;
const int K_BAND_TEXTURE_WIDTH = 4096;

uint calc_root_code(float y1, float y2, float y3) {
    // Calculate the root eligibility code for a sample-relative quadratic Bézier curve.
	// Extract the signs of the y coordinates of the three control points.
    uint i1 = uint(y1) >> 31U;
	uint i2 = uint(y2) >> 30U;
	uint i3 = uint(y3) >> 29U;

    uint shift = (i2 & 2U) | (i1 & ~2U);
    shift = (i3 & 4U) | (shift & ~4U);

	// Eligibility is returned in bits 0 and 8.

    return ((0x2E74U >> shift) & 0x0101U);
}

vec2 solve_horiz_poly(vec4 p12, vec2 p3) {
    vec2 a = p12.xy - p12.zw * 2.0 + p3;
    vec2 b = p12.xy - p12.zw;
    float ra = 1.0 / a.y;
    float rb = 0.5 / b.y;

    float d = sqrt(max(b.y * b.y - a.y * p12.y, 0.0));
    float t1 = (b.y - d) * ra;
    float t2 = (b.y + d) * ra;

	// If the polynomial is nearly linear, then solve -2b t + c = 0.
    float comp_less = step(abs(a.y), (1.0 / 65536.0));
    if (comp_less == 0.0 ) {
        t1 = p12.y * rb;
        t2 = t1;
    }

	// Return the x coordinates where C(t) = 0.
    // step(a,b): if a less than b returns 0.0, else if equal or greather than returns 1.0.
	return (vec2((a.x * t1 - b.x * 2.0) * t1 + p12.x, (a.x * t2 - b.x * 2.0) * t2 + p12.x));
}

vec2 solve_vert_poly(vec4 p12, vec2 p3) {
    // Solve for the values of t where the curve crosses x = 0.

    vec2 a = p12.xy - p12.zw * 2.0 + p3;
    vec2 b = p12.xy - p12.zw;
    float ra = 1.0 / a.x;
    float rb = 0.5 / b.x;

    float d = sqrt(max(b.x * b.x - a.x * p12.x, 0.0));
    float t1 = (b.x - d) * ra;
    float t2 = (b.x + d) * ra;

	// If the polynomial is nearly linear, then solve -2b t + c = 0.
    // step(a,b): if a less than b returns 0.0, else if equal or greather than returns 1.0.
    float comp_less = step(abs(a.x), (1.0 / 65536.0));
    if (comp_less == 0.0) {
        t1 = p12.x * rb;
        t2 = t1;
    }

	// Return the y coordinates where C(t) = 0.
	return (vec2((a.y * t1 - b.y * 2.0) * t1 + p12.y, (a.y * t2 - b.y * 2.0) * t2 + p12.y));
}

ivec2 calc_band_loc(ivec2 glyph_loc, uint offset) {
    ivec2 band_loc = ivec2(glyph_loc.x + int(offset), glyph_loc.y);
    band_loc.y += band_loc.x >> K_LOG_BAND_TEXTURE_WIDTH;
    band_loc.x &= K_BAND_TEXTURE_WIDTH - 1;  // ??? WGSL != HLSL
    return band_loc;
}

float calc_coverage(float xcov, float ycov, float xwgt, float ywgt) {

    // Combine coverages from the horizontal and vertical rays using their weights.
	// Absolute values ensure that either winding direction convention works.
    float coverage = max(
        abs(xcov * xwgt + ycov * ywgt) / max(xwgt + ywgt, 1.0 / 65536.0),
        min(abs(xcov), abs(ycov)),
    );
    coverage = clamp(coverage, 0.0, 1.0);
    return coverage;
}


// =============== go on here ===============

//@fragment
//fn fs_main(input: VertexOutput) -> @location(0) vec4<f32> {
void main() {
    let render_coord = input.texcoord;
    let band_transform = input.banding;
    let glyph_data = input.glyph;

    let ems_per_pixel = fwidthFine(render_coord);
    let pixels_per_em = 1.0 / ems_per_pixel;

    var band_max = glyph_data.zw;
    band_max.y &= 0x00FF;

    let band_index = clamp(
        vec2<i32>(vec2<f32>(render_coord * band_transform.xy + band_transform.zw)),
        vec2<i32>(0, 0),
        band_max,
    );
    let glyph_loc = glyph_data.xy;

    // ── Horizontal bands ──

    var xcov: f32 = 0.0;
    var xwgt: f32 = 0.0;

    let hband_data = textureLoad(band_texture, vec2<i32>(glyph_loc.x + band_index.y, glyph_loc.y), 0).xy;
    let hband_loc = calc_band_loc(glyph_loc, hband_data.y);

    for (var ci: i32 = 0; ci < i32(hband_data.x); ci++) {
        let curve_loc = vec2<i32>(textureLoad(band_texture, vec2<i32>(hband_loc.x + ci, hband_loc.y), 0).xy);

        let p12 = textureLoad(curve_texture, curve_loc, 0) - vec4<f32>(render_coord, render_coord);
        let p3 = textureLoad(curve_texture, vec2<i32>(curve_loc.x + 1, curve_loc.y), 0).xy - render_coord;

        // Early exit: curves sorted by descending max-x
        if max(max(p12.x, p12.z), p3.x) * pixels_per_em.x < -0.5 {
            break;
        }

        let code = calc_root_code(p12.y, p12.w, p3.y);
        if code != 0u {
            let r = solve_horiz_poly(p12, p3) * pixels_per_em.x;

            if (code & 1u) != 0u {
                xcov += clamp(r.x + 0.5, 0.0, 1.0);
                xwgt = max(xwgt, clamp(1.0 - abs(r.x) * 2.0, 0.0, 1.0));
            }
            if code > 1u {
                xcov -= clamp(r.y + 0.5, 0.0, 1.0);
                xwgt = max(xwgt, clamp(1.0 - abs(r.y) * 2.0, 0.0, 1.0));
            }
        }
    }

    // ── Vertical bands ──

    var ycov: f32 = 0.0;
    var ywgt: f32 = 0.0;

    let vband_data = textureLoad(band_texture, vec2<i32>(glyph_loc.x + band_max.y + 1 + band_index.x, glyph_loc.y), 0).xy;
    let vband_loc = calc_band_loc(glyph_loc, vband_data.y);

    for (var ci: i32 = 0; ci < i32(vband_data.x); ci++) {
        let curve_loc = vec2<i32>(textureLoad(band_texture, vec2<i32>(vband_loc.x + ci, vband_loc.y), 0).xy);

        let p12 = textureLoad(curve_texture, curve_loc, 0) - vec4<f32>(render_coord, render_coord);
        let p3 = textureLoad(curve_texture, vec2<i32>(curve_loc.x + 1, curve_loc.y), 0).xy - render_coord;

        // Early exit: curves sorted by descending max-y
        if max(max(p12.y, p12.w), p3.y) * pixels_per_em.y < -0.5 {
            break;
        }

        let code = calc_root_code(p12.x, p12.z, p3.x);
        if code != 0u {
            let r = solve_vert_poly(p12, p3) * pixels_per_em.y;

            if (code & 1u) != 0u {
                ycov -= clamp(r.x + 0.5, 0.0, 1.0);
                ywgt = max(ywgt, clamp(1.0 - abs(r.x) * 2.0, 0.0, 1.0));
            }
            if code > 1u {
                ycov += clamp(r.y + 0.5, 0.0, 1.0);
                ywgt = max(ywgt, clamp(1.0 - abs(r.y) * 2.0, 0.0, 1.0));
            }
        }
    }

    let coverage = calc_coverage(xcov, ycov, xwgt, ywgt);
    return input.color * coverage;
}