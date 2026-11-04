#version 110

/* scaled */
uniform vec2 frame_size;

varying float stroke_width;
varying float stroke_width_half;
varying float radius;

varying vec4 fill_color;
varying vec4 stroke_color;

varying vec4 rect_coords; //x1 [0], x2 [1], y1 [2], y2 [3]; coords of the rect_frame
varying vec2 rect_size_half;


float calc_distance(vec2 p, vec2 b, float r)
{
    vec2 d = abs(p) - b + vec2(r);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - r;   
}

void main() {

float edge_softness;
edge_softness = 1.0;

    if (radius == 0.0) {
        vec4 color = fill_color;
        if (gl_FragCoord.x >= rect_coords[1] - stroke_width ){
            color = stroke_color;
        } else if (gl_FragCoord.x <= rect_coords[0] + stroke_width){
            color = stroke_color;
        } else if (gl_FragCoord.y <= frame_size.y - rect_coords[3] + stroke_width ){
            color = stroke_color;
        } else if (gl_FragCoord.y >= frame_size.y - rect_coords[2] - stroke_width ){
            color = stroke_color;
        }
        gl_FragColor = color; 
          
    } else {

        vec4 frag_rect_coords = vec4(rect_coords[0], rect_coords[1], frame_size.y - rect_coords[3], frame_size.y - rect_coords[2]);
        vec2 vec_centered_pos = (gl_FragCoord.xy - vec2(frag_rect_coords[0] + frag_rect_coords[1], frag_rect_coords[2] + frag_rect_coords[3]) * 0.5);

        float distance = calc_distance(vec_centered_pos, rect_size_half, radius - stroke_width_half);

        vec4 final_color;
        float final_alpha;

        if (stroke_width_half > 0.0)
        {
            float color_blend = smoothstep(-stroke_width_half - edge_softness, -stroke_width_half + edge_softness, distance);
            final_color = mix(fill_color, stroke_color, color_blend);
            final_alpha = 1.0 - smoothstep(stroke_width_half - edge_softness, stroke_width_half + edge_softness, distance);
        }
        else
        {
            final_color = fill_color;
            final_alpha = 1.0 - smoothstep(-edge_softness, edge_softness, distance);
        }

        // final color
        gl_FragColor = vec4(final_color.rgb, final_color.a * final_alpha);

    } 
}