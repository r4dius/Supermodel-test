/**
 ** Supermodel
 ** A Sega Model 3 Arcade Emulator.
 ** Copyright 2011-2016 Bart Trzynadlowski, Nik Henson 
 **
 ** This file is part of Supermodel.
 **
 ** Supermodel is free software: you can redistribute it and/or modify it under
 ** the terms of the GNU General Public License as published by the Free 
 ** Software Foundation, either version 3 of the License, or (at your option)
 ** any later version.
 **
 ** Supermodel is distributed in the hope that it will be useful, but WITHOUT
 ** ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 ** FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 ** more details.
 **
 ** You should have received a copy of the GNU General Public License along
 ** with Supermodel.  If not, see <http://www.gnu.org/licenses/>.
 **/
 
/*
 * Fragment.glsl
 *
 * Fragment shader for 3D rendering.
 */

#version 320 es
// Global uniforms
uniform sampler2D textureMap;
uniform vec4 spotEllipse;
uniform vec2 spotRange;
uniform vec3 spotColor;
uniform vec3 lighting[2];
uniform float mapSize;

// Inputs from vertex shader
in vec4 fsSubTexture;
in vec4 fsTexParams;
in float fsTexFormat;
in float fsTexMap;
in float fsTransLevel;
in vec3 fsLightIntensity;
in float fsSpecularTerm;
in float fsFogFactor;
in float fsViewZ;

void main()
{
vec2 tc;
vec4 texCol, finalCol;
vec3 finalColor, color, lightIntensity;
float fogFactor, depth;

tc = fsSubTexture.xy / mapSize;
texCol = texture(textureMap, tc);

if (fsTransLevel < 0.5)
fsTransLevel = 1.0;

finalCol = texture(textureMap, tc);
finalCol *= vec4(vec3(finalCol.r) * finalCol.a, finalCol.a) * fsTransLevel;

if (fsTexMap == 0.0) {
finalColor = finalCol.rgb;
}
else {
finalColor = texture(textureMap, tc).rgb;
finalColor = finalColor * (1.0 - fsTransLevel);
}

color = lighting[0].xyz * finalColor + lighting[1].xyz;

depth = (fsViewZ - spotRange.x) / (spotRange.y - spotRange.x);
fogFactor = (exp(-depth * depth) + 1.0) * 0.5;

gl_FragColor = vec4(color * (1.0 - fogFactor) + vec3(0.1, 0.1, 0.1) * fogFactor, 1.0);
}