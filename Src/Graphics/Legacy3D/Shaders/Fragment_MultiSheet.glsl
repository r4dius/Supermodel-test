/**
 ** Supermodel
 ** A Sega Model 3 Arcade Emulator.
 ** Copyright 2011-2012 Bart Trzynadlowski, Nik Henson 
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
 * Fragment_MultiSheet.glsl
 *
 * Fragment shader for 3D rendering. Uses 8 texture sheets to decode the 
 * different possible formats.
 */

#version 320 es
// Global uniforms
uniform sampler2D textureMap[8];
uniform vec4 spotEllipse;
uniform vec2 spotRange;
uniform vec3 spotColor;
uniform vec3 lighting[2];
uniform int mapSize;

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
vec4 texCol, texCol2, texCol3, texCol4, texCol5, texCol6, texCol7, texCol8;
vec4 blendedTexCol, blendedTexCol2, blendedTexCol3, blendedTexCol4;
vec4 blendedTexCol5, blendedTexCol6, blendedTexCol7, blendedTexCol8;
vec4 finalCol, finalCol2, finalCol3, finalCol4, finalCol5, finalCol6, finalCol7, finalCol8;
vec3 finalColor, color, lightIntensity;
float fogFactor, depth, mirrorEnable, texWrapU, texWrapV;

texWrapU = fsTexParams.z;
texWrapV = fsTexParams.w;
mirrorEnable = step(fsTexParams.x, 0.5);
depth = (fsViewZ - spotRange.x) / (spotRange.y - spotRange.x);

tc = fsSubTexture.xy / mapSize;
tc.x = (tc.x - floor(tc.x)) * mapSize;
tc.y = (tc.y - floor(tc.y)) * mapSize;

if (texWrapU > 0.5)
tc.x = mirrorEnable * (mapSize - tc.x) + (1.0 - mirrorEnable) * tc.x;

if (texWrapV > 0.5)
tc.y = mirrorEnable * (mapSize - tc.y) + (1.0 - mirrorEnable) * tc.y;

texCol = texture(textureMap[int(fsTexMap)], tc);

if (fsTexFormat > 0.5) {
if (texCol.a < 0.1)
discard;
texCol.rgb = vec3(1.0) - texCol.rgb;
}

if (fsTransLevel < 0.5)
fsTransLevel = 1.0;

blendedTexCol = vec4(vec3(texCol.r * texCol.a), texCol.a) * fsTransLevel;

if (fsTexMap == 0.0) {
finalCol = blendedTexCol;
}
else {
finalCol = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol = vec4(vec3(finalCol.r * finalCol.a), finalCol.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 1.0) {
finalCol2 = blendedTexCol;
}
else {
finalCol2 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol2 = vec4(vec3(finalCol2.r * finalCol2.a), finalCol2.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 2.0) {
finalCol3 = blendedTexCol;
}
else {
finalCol3 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol3 = vec4(vec3(finalCol3.r * finalCol3.a), finalCol3.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 3.0) {
finalCol4 = blendedTexCol;
}
else {
finalCol4 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol4 = vec4(vec3(finalCol4.r * finalCol4.a), finalCol4.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 4.0) {
finalCol5 = blendedTexCol;
}
else {
finalCol5 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol5 = vec4(vec3(finalCol5.r * finalCol5.a), finalCol5.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 5.0) {
finalCol6 = blendedTexCol;
}
else {
finalCol6 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol6 = vec4(vec3(finalCol6.r * finalCol6.a), finalCol6.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 6.0) {
finalCol7 = blendedTexCol;
}
else {
finalCol7 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol7 = vec4(vec3(finalCol7.r * finalCol7.a), finalCol7.a) * (1.0 - fsTransLevel);
}

if (fsTexMap == 7.0) {
finalCol8 = blendedTexCol;
}
else {
finalCol8 = texture(textureMap[int(fsTexMap) - 1.0], tc);
finalCol8 = vec4(vec3(finalCol8.r * finalCol8.a), finalCol8.a) * (1.0 - fsTransLevel);
}

finalColor = finalCol.rgb + finalCol2.rgb + finalCol3.rgb + finalCol4.rgb + finalCol5.rgb + finalCol6.rgb + finalCol7.rgb + finalCol8.rgb;

if (fsSpecularTerm > 0.0)
finalColor = finalColor * pow(max(dot(fsLightIntensity, lightIntensity), 0.0), fsSpecularTerm);

color = vec3(lighting[0].xy) * finalColor + lighting[1].xyz;

fogFactor = (exp(-depth * depth) + 1.0) * 0.5;

gl_FragColor = vec4(color * (1.0 - fogFactor) + fogColor.rgb * fogFactor, 1.0);
}