#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

varying vec4 vertColor;
varying vec4 vertPosition;

uniform float maxDistance;
uniform float minDistance;

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

void main() {
  float m = map(vertPosition.z, minDistance, maxDistance, 1, 0);
  gl_FragColor = vec4(vertColor.r*m, vertColor.g*m, vertColor.b*m, m);
}
