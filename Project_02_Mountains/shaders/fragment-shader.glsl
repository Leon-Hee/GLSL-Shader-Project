
varying vec2 vUvs;
uniform vec2 resolution;
uniform float time;

float inverseLerp(float v, float minValue, float maxValue) {
  return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax) {
  float t = inverseLerp(v, inMin, inMax);
  return mix(outMin, outMax, t);
}


vec3 hash( vec3 p )
{
	p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
            dot(p,vec3(269.5,183.3,246.1)),
            dot(p,vec3(113.5,271.9,124.6)));

	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( in vec3 p )
{
  vec3 i = floor( p );
  vec3 f = fract( p );
	
	vec3 u = f*f*(3.0-2.0*f);

  return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                        dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                   mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                        dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
              mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                        dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                   mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                        dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

// fractional browniam motion
float fbm(vec3 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 1.0;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;
  total = smoothstep(-1.0, 1.0, total);

  return total;
}

// fractional browniam motion
float ridgedFBM(vec3 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 1.0;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    noiseValue = abs(noiseValue);
    noiseValue = 1.0 - noiseValue;

    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;
  total *= total;

  return total;
}

// fractional browniam motion
float turblanceFBM(vec3 p, int octaves, float persistence, float lacunarity) {
  float amplitude = 1.0;
  float frequency = 1.0;
  float total = 0.0;
  float normalization = 0.0;

  for (int i = 0; i < octaves; ++i) {
    float noiseValue = noise(p * frequency);
    noiseValue = abs(noiseValue);

    total += noiseValue * amplitude;
    normalization += amplitude;
    amplitude *= persistence;
    frequency *= lacunarity;
  }

  total /= normalization;

  return total;
}

float cellular(vec3 coords){
  vec2 gridBasePosition = floor(coords.xy);
  vec2 gridCoordOffset = fract(coords.xy); 

  float closest = 1.0; 
  for(float y = -2.0; y <= 2.0; y += 1.0){
    for(float x = -2.0; x <= 2.0; x += 1.0){
      vec2 neighbourCellPosition = vec2(x,y); 
      vec2 cellWorldPosition = gridBasePosition + neighbourCellPosition;
      vec2 cellOffset = vec2(
        noise(vec3(cellWorldPosition, coords.z) + vec3(243.432, 324.235, 0.0)),
        noise(vec3(cellWorldPosition, coords.z))
      );
      float distToNeighbour = length(neighbourCellPosition + cellOffset - gridCoordOffset); 
      closest = min(closest, distToNeighbour);
    }
  }
  return closest;
}

float stepped(float noiseSample){
  float steppedSample = floor(noiseSample * 10.0) / 10.0; 
  float remainder = fract(noiseSample * 10.0); 
  steppedSample = (steppedSample - remainder) * 0.5 + 0.5; 
  return steppedSample;
}

float domainWarpingFBM(vec3 coords){
  vec3 offset = vec3(
    fbm(coords, 4, 0.5, 2.0),
    fbm(coords + vec3(43.235,23.112,0.0),4,0.5,2.0),0.0
  );
  float noiseSample = fbm(coords + offset, 1, 0.5, 2.0);

  vec3 offset2 = vec3(
      fbm(coords + 4.0 * offset + vec3(5.325, 1.421, 3.235), 4, 0.5, 2.0),
      fbm(coords + 4.0 * offset + vec3(4.32,0.532,6.324),4,0.5,2.0),0.0
  );
  noiseSample = fbm(coords + 4.0 * offset2, 1, 0.5, 2.0);

  vec3 offset3 = vec3(
      fbm(coords + 8.0 * offset + vec3(7.653, 6.41, 2.35), 4, 0.5, 2.0),
      fbm(coords + 8.0 * offset + vec3(7.561,5.32,6.324),4,0.5,2.0),0.0
  );
  noiseSample = fbm(coords + 8.0 * offset3, 1, 0.5, 2.0);

  return noiseSample;
}

vec3 GenerateSky() {
  vec3 color_1 = vec3(0.4, 0.6, 0.9);
  vec3 color_2 = vec3(0.1, 0.15, 0.4);
  return mix(
    color_1, color_2, smoothstep(0.875, 1.0, vUvs.y)
  );
}

vec3 DrawMountains(vec3 background, vec3 mountainColor, vec2 pixelCoords, float deepth) {
  float y = fbm(
    vec3(deepth + pixelCoords.x / 256.0, 1.432, 3.643), 6, 0.5, 2.0
  ) * 256.0;

  vec3 fogColor = vec3(0.4, 0.6, 0.9);
  float fogFactor = smoothstep(0.0, 8000.0, deepth * 0.5);

  float heightFactor = smoothstep(256.0, -512.0, pixelCoords.y);
  heightFactor *= heightFactor;
  fogFactor = mix(heightFactor, fogFactor, fogFactor);

  mountainColor = mix(mountainColor, fogColor, fogFactor);

  float sdfMountain = pixelCoords.y - y;

  float blur = 1.0 + smoothstep(200.0, 6000.0, deepth) * 64.0 + smoothstep(200.0, -1400.0, deepth) * 128.0;
  vec3 color = mix(
    mountainColor, 
    background, 
    smoothstep(0.0, blur, sdfMountain));
  return color;
}

void main() {
  vec2 pixelCoords = (vUvs - 0.5) * resolution;
  vec3 color = GenerateSky();

  vec2 timeOffset = vec2(time * 50.0, 0.0);

  vec2 mountainCoords = (pixelCoords - vec2(0.0, 300.0)) * 8.0 + timeOffset;
  color = DrawMountains(color, vec3(0.5), mountainCoords, 6000.0);
  mountainCoords = (pixelCoords - vec2(0.0, 260.0)) * 4.0 + timeOffset;
  color = DrawMountains(color, vec3(0.45), mountainCoords, 3200.0);
  mountainCoords = (pixelCoords - vec2(0.0, 180.0)) * 2.0 + timeOffset;
  color = DrawMountains(color, vec3(0.4), mountainCoords, 1600.0);
  mountainCoords = (pixelCoords - vec2(0.0, 20.0)) * 1.0 + timeOffset;
  color = DrawMountains(color, vec3(0.35), mountainCoords, 800.0);
  mountainCoords = (pixelCoords - vec2(0.0, -200.0)) * 0.5 + timeOffset;
  color = DrawMountains(color, vec3(0.3), mountainCoords, 400.0);
  mountainCoords = (pixelCoords - vec2(0.0, -600.0)) * 0.25 + timeOffset;
  color = DrawMountains(color, vec3(0.25), mountainCoords, 0.0);

  
  gl_FragColor = vec4(color, 1.0);
}