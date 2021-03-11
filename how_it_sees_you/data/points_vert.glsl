uniform mat4 transform;

attribute vec4 vertex;
attribute vec4 color;

varying vec4 vertColor;
varying vec4 vertPosition;

uniform float pointSize;
uniform float maxDistance;


void main() {
  gl_Position = transform * vertex;
  gl_PointSize = pointSize;
  vertColor = color;
  vertPosition = gl_Position;
}
