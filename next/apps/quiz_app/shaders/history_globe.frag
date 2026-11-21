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
  vec4 relief = texture(uEarth, vec2(fract(0.5 + lon/(2.0*pi)), 0.5 - lat/pi));
  float water = smoothstep(0.025, 0.20, relief.b - relief.r);
  vec3 sage = vec3(
    relief.r * 0.45 + relief.g * 0.45 + 0.11,
    relief.g * 0.85 + 0.08,
    relief.g * 0.73 + 0.10
  );
  fragColor = vec4(mix(relief.rgb, sage, water * 0.92), relief.a);
}
