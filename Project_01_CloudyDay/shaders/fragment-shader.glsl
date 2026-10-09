
in vec2 vUvs;
uniform vec2 resolution;
uniform float time;

vec3 yellow = vec3(1.0, 1.0, 0.5);
vec3 blue = vec3(0.25, 0.25, 1.0);
vec3 red = vec3(1.0, 0.25, 0.25);
vec3 green = vec3(0.25, 1.0, 0.25);
vec3 purple = vec3(1.0, 0.25, 1.0);

float inverseLerp(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
    float t = inverseLerp(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

vec3 BackgroundColor() {
    float disFromCenter = length(abs(vUvs - 0.5));
    float vignette = 1.0 - disFromCenter;
    vignette = smoothstep(0.0, 0.7, vignette);
    vignette = remap(vignette, 0.0, 1.0, 0.3, 1.0);
    return vec3(vignette);
}

vec3 drawGrid(vec3 color, vec3 lineColor, float cellSapcing, float lineWidth) {
    vec2 center = vUvs - 0.5;
    vec2 cells = abs(fract(center * resolution / vec2(cellSapcing)) - 0.5);
    float distToEdge = (0.5 -  max(cells.x, cells.y)) * cellSapcing;
    float lines = smoothstep(0.0, lineWidth, distToEdge);

    color = mix(lineColor, color, lines);

    return color;
}

float sdfCircle(vec2 p, float r) {
    return length(p) - r;
}

float sdfLine(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);

    return length(pa - ba * h);
}

float sdfBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

mat2 rotate2D(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

float opIntersection(float d1, float d2) {
    return max(d1, d2);
}

float softMax(float a, float b, float k) {
    return log(exp(k * a) + exp(k * b)) / k;
}

float softMin(float a, float b, float k) {
    return -softMax(-a, -b, k);
}

float softMinValue(float a, float b, float k) {
    float h = remap(a - b, -1.0 / k, 1.0 / k, 0.0, 1.0);
    return h;
}

float easeOutBounce(float x) {
    const float n1 = 7.5625;
    const float d1 = 2.75;

    if(x < 1.0 / d1) {
        return n1 * x * x;
    } else if(x < 2.0 / d1) {
        x -= 1.5 / d1;
        return n1 * x * x + 0.75;
    } else if(x < 2.5 / d1) {
        x -= 2.25 / d1;
        return n1 * x * x + 0.9375;
    } else {
        x -= 2.625 / d1;
        return n1 * x * x + 0.984375;
    }
}

vec3 drawBackground(float dayTime) {
    vec3 morning = mix(
        vec3(0.44, 0.64, 0.84),
        vec3(0.34, 0.51, 0.94),
        smoothstep(0.0, 1.0, pow(vUvs.x * vUvs.y, 0.5))
    );
    vec3 midday = mix(
        vec3(0.42, 0.58, 0.75),
        vec3(0.36, 0.46, 0.82),
        smoothstep(0.0, 1.0, pow(vUvs.x * vUvs.y, 0.5))
    );
    vec3 evening = mix(
        vec3(0.82, 0.51, 0.25),
        vec3(0.88, 0.71, 0.39),
        smoothstep(0.0, 1.0, pow(vUvs.x * vUvs.y, 0.5))
    );
    vec3 night = mix(
        vec3(0.07, 0.1, 0.19),
        vec3(0.19, 0.2, 0.29),
        smoothstep(0.0, 1.0, pow(vUvs.x * vUvs.y, 0.5))
    );

    float dayLength = 20.0;


    vec3 color;
    if(dayTime < dayLength * 0.25) {
        color = mix(morning, midday, smoothstep(0.0, dayLength * 0.25, dayTime));
    } else if (dayTime < dayLength * 0.5) {
        color = mix(midday, evening, smoothstep(dayLength * 0.25, dayLength * 0.5, dayTime));
    } else if (dayTime < dayLength * 0.75) {
        color = mix(evening, night, smoothstep(dayLength * 0.5, dayLength * 0.75, dayTime));
    } else {
        color = mix(night, morning, smoothstep(dayLength * 0.75, dayLength, dayTime));
    }


    return color;
}

float sdfCloud(vec2 pixelCoords) {
    float puff1 = sdfCircle(pixelCoords, 100.0);
    float puff2 = sdfCircle(pixelCoords - vec2(120.0, -10.0), 75.0);
    float puff3 = sdfCircle(pixelCoords + vec2(120.0, 10.0), 75.0);

    return min(puff1, min(puff2, puff3));
}

float sdfMoon(vec2 pixelCoords) {
    float d = opSubtraction(sdfCircle(pixelCoords + vec2(50.0, 0.0), 80.0),
        sdfCircle(pixelCoords, 80.0));
    return d;
}

float sdfStar(in vec2 p, in float r, in float rf) {
    const vec2 k1 = vec2(0.809016994375, -0.587785252292);
    const vec2 k2 = vec2(-k1.x, k1.y);
    p.x = abs(p.x);
    p -= 2.0 * max(dot(k1, p), 0.0) * k1;
    p -= 2.0 * max(dot(k2, p), 0.0) * k2;
    p.x = abs(p.x);
    p.y -= r;
    vec2 ba = rf * vec2(-k1.y, k1.x) - vec2(0, 1);
    float h = clamp(dot(p, ba) / dot(ba, ba), 0.0, r);
    return length(p - ba * h) * sign(p.y * ba.x - p.x * ba.y);
}

float hash(vec2 v) {
    float t = dot(v, vec2(36.5323, 73.945));
    return sin(t);
}

float saturate(float t) {
    return clamp(t, 0.0, 1.0);
}

float easeOut(float x, float p) {
    return 1.0 - pow(1.0 - x, p);
}

void main(){
    vec2 pixelCoords = vUvs * resolution;

    float dayLength = 20.0;
    float dayTime = mod(time + 8.0, dayLength);
    vec3 color = drawBackground(dayTime);


    // SUN
    if (dayTime < dayLength * 0.75) {
        float t = saturate(inverseLerp(dayTime, 0.0, 1.0));


        vec2 offset = vec2(200.0, resolution.y * 0.8) + mix(
            vec2(0.0, 400.0), vec2(0.0), easeOut(t, 5.0)
        );

        if(dayTime > dayLength * 0.5) {
            t = saturate(inverseLerp(dayTime, dayLength * 0.5, dayLength * 0.5 + 1.0));
            offset = vec2(200.0, resolution.y * 0.8) + mix(vec2(0.0), vec2(0.0, 400), t);
        }
        vec2 sunPos = pixelCoords - offset;

        float sun = sdfCircle(sunPos, 100.0);
        color = mix(yellow, color, smoothstep(0.0, 2.0, sun));

        float s = max(0.001, sun);
        float p = saturate(exp(-0.001 * s * s));
        color += 0.5 * mix(vec3(0.0), vec3(0.9, 0.85, 0.47), p * 0.5);
    }

    // MOON
    if (dayTime > dayLength * 0.5) {
        float t = saturate(inverseLerp(dayTime, dayLength * 0.5, dayLength * 0.5 + 1.5));


        vec2 offset =  resolution * 0.8 + mix(
            vec2(0.0, 400.0), vec2(0.0), easeOutBounce(t)
        );

        if(dayTime > dayLength * 0.9) {
            t = saturate(inverseLerp(dayTime, dayLength * 0.9, dayLength * 0.95));
            offset = resolution * 0.8 + mix(vec2(0.0), vec2(0.0, 400), t);
        }
        
        vec2 moonShadowPos = pixelCoords - offset + vec2(15.0);
        moonShadowPos = rotate2D(3.14159 * -0.2) * moonShadowPos;

        float moonShadow = sdfMoon(moonShadowPos);
        color = mix(vec3(0.0), color, smoothstep(-40.0, 10.0, moonShadow));

        vec2 moonPos = pixelCoords - offset;
        moonPos = rotate2D(3.14159 * -0.2) * moonPos;

        float moon = sdfMoon(moonPos);
        color = mix(vec3(1.0), color, smoothstep(0.0, 2.0, moon));

        float moonGlow = sdfMoon(moonPos);
        color += 0.1 * mix(vec3(1.0), vec3(0.0), smoothstep(-10.0, 15.0, moonGlow));

        
        
    }


    //CLOUD
    const float NUM_CLOUDS = 8.0;
    for (float i = 0.0; i < NUM_CLOUDS; i++) {
        float size = mix(2.0, 1.0, (i / NUM_CLOUDS) + 0.1 * hash(vec2(i)));
        float speed = size * 0.25;
        vec2 offset = vec2(i * 200.0 + time * 100.0 * speed, 200.0 * hash(vec2(i)));
        vec2 pos = pixelCoords - offset;

        pos = mod(pos, resolution);
        pos = pos - resolution * 0.5;

        float cloud = sdfCloud(pos * size);
        float cloudShadow = sdfCloud(pos * size + vec2(25.0)) - 50.0;
        color = mix(color, vec3(0.0), 0.5 * smoothstep(0.0, -100.0, cloudShadow));
        color = mix(vec3(1.0), color, smoothstep(0.0, 1.0, cloud));
    
    }

    //STARS
    const float NUM_STARS = 24.0;
    for (float i = 0.0; i < NUM_STARS; i++) {
        float hashSample = hash(vec2(i * 13.0)) * 0.5 + 0.5;
        float t = saturate(inverseLerp(dayTime + hashSample * 0.5, dayLength * 0.5, dayLength * 0.5 + 1.5));

        float fade = 0.0;
        if(dayTime > dayLength * 0.9) {
            fade = saturate(
                inverseLerp(
                    dayTime - hashSample * 0.25,
                    dayLength * 0.9,
                    dayLength * 0.95
                )
            );
        }

        float size = mix(2.0, 1.0, hash(vec2(i, i + 1.0)));
        vec2 offset = vec2(i * 100.0, 0.0) + 150.0 * hash(vec2(i));
        offset += mix(vec2(0.0, 600.0), vec2(0.0), easeOutBounce(t));

        float rot = mix(-3.14159, 3.14159, hashSample);

        vec2 pos = pixelCoords - offset;
        pos.x = mod(pos.x, resolution.x);
        pos = pos - resolution * vec2(0.5, 0.75);
        pos = rotate2D(rot) * pos;
        pos *= size;

        float star = sdfStar(pos, 10.0, 2.0);
        vec3 starColor = mix(vec3(1.0), color, smoothstep(0.0, 2.0, star));
        starColor += mix(0.2, 0.0, pow(smoothstep(-5.0, 15.0, star), 0.25));
        color = mix(starColor, color, fade);
    
    }
    
    gl_FragColor = vec4(color, 1.0);   
}