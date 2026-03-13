uniform vec3 lightPosition;

varying vec3 vFragPos;
varying vec3 vCameraPos;
varying vec3 vLightPos;

void main() {
    // set up in object's local space
    vFragPos = position;
    vCameraPos = vec3( inverse(modelMatrix) * vec4(cameraPosition, 1.0) );
    vLightPos = vec3( inverse(modelMatrix) * vec4(lightPosition, 1.0) );
    
    gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}