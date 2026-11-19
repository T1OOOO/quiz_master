#include <flutter/runtime_effect.glsl>

uniform vec2 uCenter;
uniform float uRadius;
uniform float uLongitude;
uniform float uLatitude;
uniform sampler2D uEarth;
out vec4 fragColor;

void main() {
  // Inverse orthographic projection in the same camera frame as the borders.
  vec2 p = (FlutterFragCoord().xy - uCenter) / uRadius;
  float z = sqrt(max(0.0, 1.0 - dot(p, p)));
  float c = cos(uLatitude), s = sin(uLatitude);
  float lat = asin(clamp(z*s - p.y*c, -1.0, 1.0));
  float meridian = z*c + p.y*s;
  float lon = uLongitude;
  if (abs(p.x) + abs(meridian) > 0.000001) {
    lon += atan(p.x, meridian);
  }
  const float pi = 3.14159265359;
  fragColor = texture(uEarth, vec2(fract(0.5 + lon/(2.0*pi)), 0.5 - lat/pi));
}
