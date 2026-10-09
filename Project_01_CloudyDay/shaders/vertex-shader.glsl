
out vec3 vNormal;
out vec3 vPosition;
out vec3 vColor;
out vec2 vUvs;

uniform float time;

float inverseStep(float v, float minValue, float maxValue) {
    return (v - minValue) / (maxValue - minValue);
}

float remap(float v, float inMin, float inMax, float outMin, float outMax){
    float t = inverseStep(v, inMin, inMax);
    return mix(outMin, outMax, t);
}

mat3 rotateY(float radians) {
    float s = sin(radians);
    float c = cos(radians);

    return mat3(
        c, 0.0, s, 
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
}

void main(){
    vec3 localSpacePosition = position;


    gl_Position = projectionMatrix * modelViewMatrix * vec4(localSpacePosition, 1.0);
    vNormal = (modelViewMatrix * vec4(normal, 0.0)).xyz;
    vPosition = (modelViewMatrix * vec4(vPosition, 1.0)).xyz;
    vUvs = uv;

}