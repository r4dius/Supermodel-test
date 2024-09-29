/**
 ** Supermodel
 ** A Sega Model 3 Arcade Emulator.
 ** Copyright 2011 Bart Trzynadlowski, Nik Henson 
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
 * Fragment_NoSpotlight.glsl
 *
 * Fragment shader for 3D rendering. Spotlight effect removed. Fixes fragment
 * shader link errors on older ATI Radeon GPUs.
 *
 * To load external fragment shaders, use the -frag-shader=<file> option when
 * starting Supermodel.
 */

#version 320 es

// Global uniforms
uniform sampler2D textureMap;
uniform vec4 spotEllipse;
uniform vec2 spotRange;
uniform vec3 spotColor;
uniform float mapSize;

// Inputs from vertex shader
in vec4 fsSubTexture;
in vec4 fsTexParams;
in float fsTexFormat;
in float fsTransLevel;
in vec3 fsLightIntensity;
in float fsFogFactor;
in float fsViewZ;

// Helper function for texture coordinate wrapping
vec4 WrapTexelCoords(vec4 texCoord, vec4 texOffset, vec4 texSize, vec4 mirrorEnable)
{
    vec4 clampedCoord = mod(texCoord, texSize);
    vec4 mirror = mirrorEnable * mod(floor(texCoord / texSize), 2.0);

    return (mirror * (texSize - clampedCoord) + (vec4(1.0, 1.0, 1.0, 1.0) - mirror) * clampedCoord + texOffset) / mapSize;
}

void main()
{
    vec4 uv_top, uv_bot;
    vec2 r;
    vec4 fragColor;
    vec2 ellipse;
    vec3 lightIntensity;
    float insideSpot;

    if (fsTexParams.x < 0.5)
        fragColor = gl_FragColor;
    else
    {
        fragColor = texture(textureMap, (fsSubTexture.xy + fsSubTexture.zw / 2.0) / mapSize);
    }

    ellipse = (gl_FragCoord.xy - spotEllipse.xy) / spotEllipse.zw;
    insideSpot = dot(ellipse, ellipse);
    if ((insideSpot <= 1.0) && (fsViewZ >= spotRange.x) && (fsViewZ < spotRange.y))
        lightIntensity = fsLightIntensity + (1.0 - insideSpot) * spotColor;
    else
        lightIntensity = fsLightIntensity;

    fragColor.rgb *= lightIntensity;
    fragColor.a *= fsTransLevel;

    fragColor.rgb = mix(gl_Fog.color.rgb, fragColor.rgb, fsFogFactor);

    gl_FragColor = fragColor;
}