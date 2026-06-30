shader_type canvas_item;

uniform int round_number : hint_range(1, 6) = 1;
uniform float time_scale : hint_range(0.0, 2.0) = 1.0;
uniform float transition : hint_range(0.0, 1.0) = 1.0; // for blending between rounds

void fragment() {
    vec2 uv = UV;
    vec2 centered = uv - 0.5;
    float t = TIME * time_scale;
    vec3 color = vec3(0.0);

    // ── ROUND 1 — Smoky Blue ──────────────────────────────
    vec3 smoky = vec3(0.04, 0.08, 0.16);
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        vec2 smoke_c = vec2(
            0.2 + fi * 0.2 + sin(t * 0.15 + fi * 1.5) * 0.08,
            0.5 + cos(t * 0.12 + fi) * 0.12
        );
        float smoke = 1.0 - smoothstep(0.0, 0.35, distance(uv, smoke_c));
        smoky += vec3(0.06, 0.18, 0.45) * pow(smoke, 2.0)
               * (0.12 + 0.06 * sin(t * 0.3 + fi));
    }

    // ── ROUND 2 — Deep Space ──────────────────────────────
    vec3 space = vec3(0.02, 0.02, 0.06);
    float nebula1 = 1.0 - smoothstep(0.0, 0.5,
        distance(uv, vec2(0.3 + sin(t * 0.2) * 0.05, 0.4)));
    float nebula2 = 1.0 - smoothstep(0.0, 0.4,
        distance(uv, vec2(0.7, 0.6 + cos(t * 0.25) * 0.05)));
    space += vec3(0.05, 0.1, 0.45) * pow(nebula1, 2.0) * (0.3 + 0.1 * sin(t * 0.4));
    space += vec3(0.25, 0.02, 0.35) * pow(nebula2, 2.0) * (0.25 + 0.1 * cos(t * 0.35));
    vec2 star_uv = uv * vec2(80.0, 50.0);
    vec2 star_id = floor(star_uv);
    float h = fract(sin(dot(star_id, vec2(127.1, 311.7))) * 43758.5);
    float twinkle = 0.4 + 0.6 * sin(t * 1.5 + h * 6.28);
    float star = smoothstep(0.95, 1.0, h) * twinkle;
    space += vec3(star * 0.9);

    // ── ROUND 3 — Gold & Black ────────────────────────────
    vec3 gold = vec3(0.06, 0.04, 0.0);
    for (int i = 0; i < 5; i++) {
        float fi = float(i);
        float vein_x = uv.x * 0.8 + sin(t * 0.3 + fi) * 0.08;
        float vein = sin(vein_x * 6.28 + fi * 1.2) * 0.5 + 0.5;
        vein = pow(vein, 6.0);
        gold += vec3(0.8, 0.55, 0.05) * vein * (0.07 + 0.04 * sin(t * 0.5 + fi));
    }
    float sweep_x = fract(t * 0.08) * 1.4 - 0.2;
    float sweep = 1.0 - smoothstep(0.0, 0.15, abs(uv.x - sweep_x));
    gold += vec3(0.9, 0.7, 0.1) * sweep * 0.15;

    // ── ROUND 4 — Neon Noir ───────────────────────────────
    vec3 neon = vec3(0.03, 0.0, 0.06);
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float y = fract(fi / 6.0 + t * 0.04);
        float line = smoothstep(0.015, 0.0, abs(uv.y - y));
        neon += vec3(0.4, 0.0, 1.0) * line * (0.08 + 0.04 * sin(t + fi));
    }
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float y = fract(fi / 4.0 + t * 0.03);
        float line = smoothstep(0.015, 0.0, abs(uv.y - y));
        neon += vec3(1.0, 0.0, 0.5) * line * (0.06 + 0.03 * sin(t * 1.3 + fi));
    }
    float gx = 0.5 + sin(t * 0.4) * 0.3;
    float gy = 0.5 + cos(t * 0.3) * 0.3;
    neon += vec3(0.3, 0.0, 0.8) * pow(1.0 - smoothstep(0.0, 0.5, distance(uv, vec2(gx, gy))), 3.0) * 0.3;
    neon += vec3(0.8, 0.0, 0.4) * pow(1.0 - smoothstep(0.0, 0.4, distance(uv, vec2(1.0-gx, 1.0-gy))), 3.0) * 0.25;

    // ── ROUND 5 — Blood Red ───────────────────────────────
    vec3 blood = vec3(0.08, 0.0, 0.0);
    float pulse = 0.5 + 0.5 * sin(t * 0.6);
    float red_orb = 1.0 - smoothstep(0.0, 0.7, length(centered));
    blood += vec3(0.6, 0.02, 0.02) * pow(red_orb, 2.0) * (0.25 + 0.1 * pulse);
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float streak = fract(t * 0.06 + fi * 0.25);
        float sd = abs(uv.x - uv.y * 0.5 - streak);
        blood += vec3(0.7, 0.04, 0.04) * smoothstep(0.04, 0.0, sd) * 0.1;
    }

    // ── ROUND 6 BOSS — all combined ───────────────────────
    vec3 boss = smoky * 0.3 + space * 0.3 + gold * 0.2 + neon * 0.5 + blood * 0.6;
    // Extra boss chaos — fast red pulse
    boss += vec3(0.5, 0.0, 0.0) * pow(red_orb, 3.0) * (0.3 + 0.2 * sin(t * 2.0));

    // ── SELECT ROUND ──────────────────────────────────────
    if (round_number == 1) color = smoky;
    else if (round_number == 2) color = space;
    else if (round_number == 3) color = gold;
    else if (round_number == 4) color = neon;
    else if (round_number == 5) color = blood;
    else color = boss;

    // ── VIGNETTE ──────────────────────────────────────────
    float vignette = 1.0 - dot(centered * 1.5, centered * 1.5);
    vignette = clamp(pow(vignette, 1.4), 0.0, 1.0);
    color *= vignette;

    // ── BREATHE ───────────────────────────────────────────
    color *= 0.92 + 0.08 * sin(t * 0.5);

    COLOR = vec4(color, 1.0);
}