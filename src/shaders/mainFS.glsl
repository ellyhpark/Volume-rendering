uniform float time;
uniform vec3 background;
uniform vec3 lightColor;

uniform vec3 boxMin;
uniform vec3 boxMax;

uniform float densityInput;

varying vec3 vFragPos;
varying vec3 vCameraPos;
varying vec3 vLightPos;

#define EPS 0.001

// referenced Will Usher
// https://www.willusher.io/webgl/2019/01/13/volume-rendering-with-webgl/
vec2 intersectBox(vec3 ro, vec3 rd) {
    vec3 rdInv = 1.0 / rd;
    vec3 tMinTmp = (boxMin - ro) * rdInv;
    vec3 tMaxTmp = (boxMax - ro) * rdInv;

    // account for when ray direction has negative values
    vec3 tMin = min(tMinTmp, tMaxTmp);
    vec3 tMax = max(tMinTmp, tMaxTmp);

    float t0 = max(tMin.x, max(tMin.y, tMin.z));
    float t1 = min(tMax.x, min(tMax.y, tMax.z));

    // no intersection
    if (t0 > t1) {
        discard;
    }
    // if camera is inside the volume, then t0 < 0
    // no need to sample behind the camera, so keep t0 >= 0
    t0 = max(t0, 0.0);

    // t0 = distance from camera to first intersection
    // t1 = distance from camera to second intersection
    return vec2(t0, t1);
}

// hash, perlinNoise, and cloud have modified code from Google Gemini ----------
vec3 hash(vec3 p) {
    p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
             dot(p, vec3(269.5, 183.3, 246.1)),
             dot(p, vec3(113.5, 271.9, 124.6)));

    // g = a pseudo-random vector with components in [-1, 1]
    vec3 g = -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
    return g * inversesqrt(max(dot(g, g), EPS)); // normalize
}

// referenced Scratchapixel
// https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/perlin-noise-part-2/perlin-noise.html
// https://www.scratchapixel.com/lessons/procedural-generation-virtual-worlds/procedural-patterns-noise-part-1/introduction.html
// set-up:
// 3D grid with pseudo-random vectors at each point
// evaluating point p and box it is in within the 3D grid
// for each corner of that box:
//     value = dot product(pseudo-random vector at the corner, vector that points from the corner to p)
// trilinear interpolation of 4 values based on p
float perlinNoise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);

    // 6t^5 - 15t^4 + 10t^3, computed through Horner's method
    // remap f to u (used for interpolation) for more gradual changes in noise values
    vec3 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    // trilinear interpolation
    return mix(
        mix(
            mix(
                dot(hash(i + vec3(0,0,0)), f - vec3(0,0,0)),
                dot(hash(i + vec3(1,0,0)), f - vec3(1,0,0)),
                u.x
            ),
            mix(
                dot(hash(i + vec3(0,1,0)), f - vec3(0,1,0)),
                dot(hash(i + vec3(1,1,0)), f - vec3(1,1,0)),
                u.x
            ),
            u.y
        ),
        mix(
            mix(
                dot(hash(i + vec3(0,0,1)), f - vec3(0,0,1)),
                dot(hash(i + vec3(1,0,1)), f - vec3(1,0,1)),
                u.x
            ),
            mix(
                dot(hash(i + vec3(0,1,1)), f - vec3(0,1,1)),
                dot(hash(i + vec3(1,1,1)), f - vec3(1,1,1)),
                u.x
            ),
            u.y
        ),
        u.z
    );
}

float cloud(vec3 p) {
    p += vec3(0.7, 0.05, 0.4) * time;

    float density = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    for (int i = 0; i < 3; i++) {
        density += amplitude * perlinNoise(p * frequency);
        frequency *= 2.0;
        amplitude *= 0.5;
    }

    return max(density, 0.0);
}

vec3 fromLightSrc(vec3 samplePos, float t, float s, float density) {
    if (density <= 0.0) return vec3(0.0);

    vec3 L = normalize(vLightPos - samplePos);
    vec2 tHit = intersectBox(samplePos, L);

    float transmission = pow(2.7, -density * t * tHit.y);
    return lightColor * transmission * density * s; // s? density?
}

// referenced SuboptimalEng, Scratchapixel, and GPU Gems
// https://github.com/SuboptimalEng/volume-rendering/blob/main/src/shaders/fragmentV2.glsl
// https://www.scratchapixel.com/lessons/3d-basic-rendering/volume-rendering-for-developers/intro-volume-rendering.html
// https://developer.nvidia.com/gpugems/gpugems/part-vi-beyond-triangles/chapter-39-volume-rendering-techniques
void main() {
    vec3 ro = vCameraPos;
    vec3 rd = normalize(vFragPos - vCameraPos);

    vec2 tHit = intersectBox(ro, rd);

    // step size to ray march through the volume
    float dt = 0.01;

    float a = 0.5; // absorption coefficient
    float s = 0.5; // scattering coefficient
    float t = a + s; // extinction coefficient

    vec3 accumColor = vec3(0.0);
    float accumOpacity = 0.0;
    vec3 samplePos = ro + tHit.x * rd;

    for (float ti = tHit.x; ti < tHit.y; ti += dt) {
        float density = cloud(samplePos);
        density *= densityInput; // for a different density volume (controlled by user)

        vec3 sampleColor = fromLightSrc(samplePos, t, s, density);
        float sampleOpacity = 1.0 - pow(2.7, -density * t * dt);

        // accumulate the color and opacity using the front-to-back
        // compositing equation
        accumColor += (1.0 - accumOpacity) * sampleColor * sampleOpacity;
        accumOpacity += (1.0 - accumOpacity) * sampleOpacity;

        // optimization: stop when near opaque
        // since most light after this point won't be very visible
        if (accumOpacity >= 0.99) {
            break;
        }

        samplePos += rd * dt;
    }

    // gl_FragColor = linearToOutputTexel( vec4(background, 1.0) ); // gamma correction/deformation

    gl_FragColor = linearToOutputTexel(
        vec4(background * (1.0 - accumOpacity) + accumColor, 1.0)
    );
}