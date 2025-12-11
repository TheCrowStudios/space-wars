shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5); // UV space (0-1)
uniform float radius = 0.3;
uniform float strength = 0.15; // pull intensity
uniform float swirl = 0.6;     // rotation

void fragment() {
    vec2 uv = UV;
    vec2 to_center = uv - center;
    float dist = length(to_center);

    if (dist < radius) {
        float effect = (radius - dist) / radius;

        // radial pull (stronger toward center)
        uv -= normalize(to_center) * pow(effect, 1.5) * strength;

        // swirl rotation: rotate (uv - center) by 'angle'
        float angle = effect * swirl;
        float s = sin(angle);
        float c = cos(angle);
        vec2 rel = uv - center;
        vec2 rotated = vec2(
            c * rel.x - s * rel.y,
            s * rel.x + c * rel.y
        );
        uv = center + rotated;
    }

    COLOR = texture(TEXTURE, uv);
}
