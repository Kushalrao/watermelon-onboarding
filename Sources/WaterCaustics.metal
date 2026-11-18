#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// Water over rock: the rock's picture wobbling a little as if seen through water, with stone grain, small
// blue-violet spots where it's yellow, and two layers of drifting caustic light split slightly into colour.
// Ported line for line from the GLSL it was designed in; `uv` runs up the screen as it did there.

static float wc_mod(float x, float y) { return x - y * floor(x / y); }

static float wc_hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float2 wc_hash2(float2 p) {
    return fract(sin(float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)))) * 43758.5453);
}

static float wc_noise(float2 p) {
    float2 i = floor(p), f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(wc_hash(i), wc_hash(i + float2(1.0, 0.0)), u.x),
               mix(wc_hash(i + float2(0.0, 1.0)), wc_hash(i + float2(1.0, 1.0)), u.x), u.y);
}

static float wc_fbm(float2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * wc_noise(p);
        // mat2(0.8, -0.6, 0.6, 0.8) * p
        p = float2(0.8 * p.x + 0.6 * p.y, -0.6 * p.x + 0.8 * p.y) * 2.03 + 11.7;
        a *= 0.5;
    }
    return v;
}

static float wc_dots(float2 p) {
    float2 n = floor(p), f = fract(p);
    float md = 1.0;
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            float2 g = float2(float(i), float(j));
            float2 r = g + wc_hash2(n + g) - f;
            md = min(md, dot(r, r));
        }
    }
    return sqrt(md);
}

// mat2(c, -s, s, c) * v
static float2 wc_rot(float a, float2 v) {
    float c = cos(a), s = sin(a);
    return float2(c * v.x + s * v.y, -s * v.x + c * v.y);
}

static float wc_caustic(float2 uv, float t) {
    const float TAU = 6.28318530718;
    float2 p = float2(wc_mod(uv.x * TAU, TAU), wc_mod(uv.y * TAU, TAU)) - 250.0;
    float2 i = p;
    float c = 1.0;
    float inten = 0.005;
    for (int n = 0; n < 4; n++) {
        float tt = t * (1.0 - (3.5 / float(n + 1)));
        i = p + float2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
        c += 1.0 / length(float2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
    }
    c /= 4.0;
    c = 1.17 - pow(c, 1.4);
    return pow(abs(c), 6.0);
}

static float3 wc_causticRGB(float2 p, float t, float spread) {
    float2 d = float2(spread, spread * 0.5);
    return float3(wc_caustic(p - d, t), wc_caustic(p, t), wc_caustic(p + d, t));
}

[[ stitchable ]] half4 waterCaustics(float2 position, SwiftUI::Layer layer, float2 size, float time) {
    float t = time;
    float2 uv = float2(position.x, size.y - position.y) / size.y;   // for procedural detail
    float2 st = position / size;                                     // 0..1, down the screen

    // Water refraction: the rock wobbles slightly
    float2 wob = float2(wc_noise(uv * 6.0 + float2(t * 0.45, 0.0)), wc_noise(uv * 6.0 + float2(3.0, t * 0.4))) - 0.5;
    wob += (float2(wc_noise(uv * 17.0 - float2(0.0, t * 0.7)), wc_noise(uv * 17.0 + float2(t * 0.6, 9.0))) - 0.5) * 0.4;
    float2 mst = st + wob * 0.007;

    // Base: colours and composition of the reference
    float3 base = float3(layer.sample(clamp(mst, 0.0, 1.0) * size).rgb);
    float bl = dot(base, float3(0.3, 0.55, 0.15));
    float lit = smoothstep(0.07, 0.22, bl);                         // 0 inside the dark void

    // Procedural stone detail on top of the soft base
    float grain = wc_fbm(wc_rot(1.1, (uv + wob * 0.007) * 30.0));
    base *= 0.92 + 0.17 * grain;
    base *= 0.95 + 0.10 * wc_noise(uv * 120.0);

    // Small blue-violet spots where the rock is yellow (lower part)
    float yellow = smoothstep(0.02, 0.10, (base.r + base.g) * 0.5 - base.b) * smoothstep(0.5, 0.75, st.y);
    float2 dp = wc_rot(0.4, uv * 85.0) + (float2(wc_fbm(uv * 9.0), wc_fbm(uv * 9.0 + 6.0)) - 0.5) * 3.0;
    float spot = 1.0 - smoothstep(0.20, 0.36, wc_dots(dp) + (wc_noise(dp * 0.35) - 0.5) * 0.12);
    base = mix(base, base * float3(0.50, 0.55, 0.95), spot * yellow * 0.4);

    // Caustics: fine ripple streaks, direction drifting across the surface
    float2 cp = wc_rot(0.75, uv) * float2(12.0, 5.0);
    cp += (float2(wc_fbm(uv * 2.2 + t * 0.05), wc_fbm(uv * 2.2 - t * 0.04 + 5.0)) - 0.5) * 0.6;
    cp += (float2(wc_fbm(uv * 6.0 + 2.0), wc_fbm(uv * 6.0 + 8.0)) - 0.5) * 0.2;
    cp += float2(t * 0.02, -t * 0.012);
    float ct = t * 0.6;
    float3 ca = wc_causticRGB(cp, ct, 0.045);
    float3 cb = wc_causticRGB(cp * 2.1 + 3.7, ct * 1.25 + 2.0, 0.075);
    float3 light = (ca * 0.5 + cb * 0.38) * (0.45 + 1.1 * wc_fbm(uv * 3.2 + float2(t * 0.05, -t * 0.04)));
    float lum = dot(light, float3(0.333));
    light = max(mix(float3(lum), light, 1.7), 0.0);
    light *= lit * (0.35 + 1.1 * bl);                               // brighter rock catches more light

    float3 col = base * (0.85 + 0.95 * light) + light * float3(0.05, 0.05, 0.06) * lit;
    return half4(half3(col), 1.0);
}

// Under the sea, looking along the sand towards the light: the picture sways as if seen through water, the
// surface overhead glints, shafts of sunlight fan down from the sun and slowly shift, and a net of caustic light
// crawls over the sand, laid back in perspective and split slightly into colour as it was over the rock.
// `flare` runs 0 → 1 at the end: the shafts widen and reach down the whole screen as if coming at the viewer, the
// sun's glow swells out from its place, and the picture goes to white.
[[ stitchable ]] half4 underwaterLight(float2 position, SwiftUI::Layer layer, float2 size, float time, float flare) {
    float t = time;
    float fl = flare * flare * (3.0 - 2.0 * flare);
    float2 st = position / size;                                     // 0..1, down the screen
    float aspect = size.x / size.y;

    // Refraction: the surface overhead sways most, the deep water and the sand hardly
    float2 wob = float2(wc_noise(st * float2(5.0, 9.0) + float2(t * 0.25, 0.0)),
                        wc_noise(st * float2(5.0, 9.0) + float2(3.0, t * 0.22))) - 0.5;
    float sway = mix(0.016, 0.004, smoothstep(0.0, 0.40, st.y));
    float3 base = float3(layer.sample(clamp(st + wob * sway, 0.0, 1.0) * size).rgb);
    float bl = dot(base, float3(0.3, 0.55, 0.15));

    // The surface from below: glints that run away towards the horizon
    float sd = 1.0 / max(0.40 - st.y, 0.02);
    float2 sp = float2((st.x - 0.5) * aspect * sd, sd) * 0.30 + float2(t * 0.015, -t * 0.03);
    float glint = wc_caustic(sp, t * 0.45) * smoothstep(0.34, 0.04, st.y);
    float3 col = base + float3(0.55, 0.85, 1.0) * glint * (0.25 + 0.9 * bl);

    // Shafts of sunlight fanning down from the sun, each drifting and breathing slowly
    float2 sun = float2(0.69, -0.06);
    float2 d = float2((st.x - sun.x) * aspect, st.y - sun.y);
    float ang = atan2(d.x, d.y);
    float shafts = wc_noise(float2(ang * 14.0 + t * 0.05, t * 0.10)) * 0.6
                 + wc_noise(float2(ang * 37.0 - t * 0.07, t * 0.16 + 4.0)) * 0.4;
    shafts = smoothstep(0.42, 0.85, shafts);
    // As the flare comes the shafts broaden, run the length of the screen and whiten
    shafts = mix(shafts, 0.55 + 0.45 * shafts, fl);
    float reach = exp(-length(d) * mix(2.6, 0.25, fl)) * mix(smoothstep(0.66, 0.22, st.y), 1.0, fl);
    col += mix(float3(0.30, 0.78, 0.95), float3(0.85, 0.97, 1.0), fl) * shafts * reach * (0.30 + 2.2 * fl);
    // and the sun's own glow swells out over everything
    col += float3(0.9, 0.98, 1.0) * exp(-length(d) * mix(7.0, 0.35, fl)) * fl * 1.6;

    // The net of light on the sand, in perspective, with a little of its colour split kept
    float fd = 1.0 / max(st.y - 0.40, 0.05);
    float2 fp = float2((st.x - 0.5) * aspect * fd, fd * 1.6) * 1.1;
    fp += (float2(wc_fbm(fp * 0.8 + t * 0.03), wc_fbm(fp * 0.8 - t * 0.025 + 5.0)) - 0.5) * 0.35;
    fp += float2(t * 0.012, t * 0.02);
    float3 net = wc_causticRGB(fp, t * 0.5, 0.035) * 0.75 + wc_causticRGB(fp * 1.9 + 3.7, t * 0.62 + 2.0, 0.05) * 0.25;
    float lum = dot(net, float3(0.333));
    net = max(mix(float3(lum), net, 1.5), 0.0);
    float floorMask = smoothstep(0.60, 0.74, st.y);
    net *= floorMask * (0.4 + 1.2 * bl);
    col = col * (1.0 + 0.55 * net) + net * float3(0.06, 0.08, 0.08);

    col = mix(col, float3(1.0), smoothstep(0.45, 1.0, flare));
    return half4(half3(col), 1.0);
}
