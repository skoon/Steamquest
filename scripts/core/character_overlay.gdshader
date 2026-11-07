shader_type spatial;
// Overlay for CharacterModel meshes: mixes a flat colour over the model for tints and hit flashes.
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float tint_strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	ALBEDO = tint_color.rgb;
	ALPHA = tint_strength;
}
