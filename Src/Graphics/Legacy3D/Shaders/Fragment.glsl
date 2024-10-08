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
 * Fragment.glsl
 *
 * Fragment shader for 3D rendering.
 */

#version 320 es
precision mediump float;

// Global uniforms
uniform sampler2D textureMap;    // complete texture map, 2048x2048 texels
uniform vec4 spotEllipse;        // spotlight ellipse position: .x=X position (screen coordinates), .y=Y position, .z=half-width, .w=half-height)
uniform vec2 spotRange;          // spotlight Z range: .x=start (viewspace coordinates), .y=limit
uniform vec3 spotColor;          // spotlight RGB color
uniform vec3 lighting[2];        // lighting state (lighting[0] = sun direction, lighting[1].x,y = diffuse, ambient intensities from 0-1.0)
uniform float mapSize;           // texture map size (2048,4096,6144 etc)

// Inputs from vertex shader 
in vec4 fsSubTexture;            // .x=texture X, .y=texture Y, .z=texture width, .w=texture height (all in texels)
in vec4 fsTexParams;             // .x=texture enable (if 1, else 0), .y=use transparency (if > 0), .z=U wrap mode (1=mirror, 0=repeat), .w=V wrap mode
in float fsTexFormat;            // T1RGB5 contour texture (if > 0)
in float fsTexMap;               // texture map number
in float fsTransLevel;           // translucence level, 0.0 (transparent) to 1.0 (opaque)
in vec3 fsLightIntensity;        // lighting intensity 
in float fsSpecularTerm;         // specular highlight
in float fsFogFactor;            // fog factor
in float fsViewZ;                // Z distance to fragment from viewpoint at origin
in vec4 gl_Color;                // fragment color from vertex shader

// Outputs
out vec4 fragColor;

/*
 * WrapTexelCoords():
 *
 * Computes the normalized OpenGL S,T coordinates within the 2048x2048 texture
 * sheet, taking into account wrapping behavior.
 *
 * Computing normalized OpenGL texture coordinates (0 to 1) within the 
 * Real3D texture sheet:
 *
 * If the texture is not mirrored, we simply have to clamp the
 * coordinates to fit within the texture dimensions, add the texture
 * X, Y position to select the appropriate one, and normalize by 2048
 * (the dimensions of the Real3D texture sheet).
 *
 *		= [(u,v)%(w,h)+(x,y)]/(2048,2048)
 *
 * If mirroring is enabled, textures are mirrored every odd multiple of
 * the original texture. To detect whether we are in an odd multiple, 
 * simply divide the coordinate by the texture dimension and check 
 * whether the result is odd. Then, clamp the coordinates as before but
 * subtract from the last texel to mirror them:
 *
 * 		= [M*((w-1,h-1)-(u,v)%(w,h)) + (1-M)*(u,v)%(w,h) + (x,y)]/(2048,2048)
 *		where M is 1.0 if the texture must be mirrored.
 *
 * As an optimization, this function computes TWO texture coordinates
 * simultaneously. The first is texCoord.xy, the second is in .zw. The other
 * parameters must have .xy = .zw.
 */
vec4 WrapTexelCoords(vec4 texCoord, vec4 texOffset, vec4 texSize, vec4 mirrorEnable)
{
    vec4 clampedCoord, mirror, glTexCoord;
    
    clampedCoord = mod(texCoord, texSize);                   // clamp coordinates to within texture size
    mirror = mirrorEnable * mod(floor(texCoord / texSize), 2.0); // whether this texel needs to be mirrored

    glTexCoord = (mirror * (texSize - clampedCoord) + 
                  (vec4(1.0, 1.0, 1.0, 1.0) - mirror) * clampedCoord + 
                  texOffset) / mapSize;
    return glTexCoord;
}

/*
 * main():
 *
 * Fragment shader entry point.
 */
void main(void)
{    
    vec4 uv_top, uv_bot, c[4];
    vec2 r;
    vec2 ellipse;
    vec3 lightIntensity;
    float insideSpot;
    
    // Get polygon color for untextured polygons (textured polygons will overwrite)
    if (fsTexParams.x < 0.5)
        fragColor = gl_Color;       
    else
    {
        /*
         * Bilinear Filtering
         *
         * In order to get this working on ATI, the number of operations is
         * reduced by putting everything into vec4s. uv_top holds the UV 
         * coordinates for the top two texels (.xy=left, .zw=right) and uv_bot
         * is for the lower two.
         */

        // Compute fractional blending factor, r, and lower left corner of texel 0
        uv_bot.xy = vec2(gl_Color.st) - vec2(0.5, 0.5);  // move into the lower left blending texel 
        r = uv_bot.xy - floor(uv_bot.xy);                // fractional part
        uv_bot.xy = floor(uv_bot.xy);                    // integral part
        
        // Compute texel coordinates
        uv_bot.xy += vec2(0.5, 0.5);                     // offset to center of pixel (should not be needed but it fixes a lot of glitches, esp. on Nvidia)
        uv_bot.zw = uv_bot.xy + vec2(1.0, 0.0);          // compute coordinates of the other three neighbors
        uv_top = uv_bot + vec4(0.0, 1.0, 0.0, 1.0);

        // Compute the properly wrapped texel coordinates
        uv_top = WrapTexelCoords(uv_top, vec4(fsSubTexture.xy, fsSubTexture.xy), vec4(fsSubTexture.zw, fsSubTexture.zw), vec4(fsTexParams.zw, fsTexParams.zw));
        uv_bot = WrapTexelCoords(uv_bot, vec4(fsSubTexture.xy, fsSubTexture.xy), vec4(fsSubTexture.zw, fsSubTexture.zw), vec4(fsTexParams.zw, fsTexParams.zw));

        // Fetch the texels
        c[0] = texture(textureMap, uv_bot.xy);   // bottom-left (base texel)
        c[1] = texture(textureMap, uv_bot.zw);   // bottom-right
        c[2] = texture(textureMap, uv_top.xy);   // top-left
        c[3] = texture(textureMap, uv_top.zw);   // top-right      

        // Interpolate texels and blend result with material color to determine final (unlit) fragment color
        c[0] += (c[1] - c[0]) * r.s;             // 2 alu
        c[2] += (c[3] - c[2]) * r.s;             // 2 alu
        fragColor = c[0] + (c[2] - c[0]) * r.t;  // 2 alu
    
        /*
         * T1RGB5:
         *
         * The transparency bit determines whether to discard pixels (if set).
         * What is unknown is how this bit behaves when interpolated. OpenGL
         * processes it as an alpha value, so it might concievably be blended
         * with neighbors. Here, an arbitrary threshold is chosen.
         *
         * To-do: blending could probably enabled and this would work even
         * better with a hard threshold.
         *
         * Countour processing also seems to be enabled for RGBA4 textures.
         * When the alpha value is 0.0 (or close), pixels are discarded 
         * entirely.
         */
        if (fsTexParams.y > 0.5)    // contour processing enabled
        {
            if (fragColor.a < 0.01) // discard anything with alpha == 0
                discard;
        }
        
        // If contour texture and not discarded, force alpha to 1.0 because will later be modified by polygon translucency
        if (fsTexFormat < 0.5)      // contour (T1RGB5) texture
            fragColor.a = 1.0;
    }

    // Compute spotlight and apply lighting
    ellipse = (gl_FragCoord.xy - spotEllipse.xy) / spotEllipse.zw;
    insideSpot = dot(ellipse, ellipse);
    if ((insideSpot <= 1.0) && (fsViewZ >= spotRange.x) && (fsViewZ < spotRange.y))
        lightIntensity = fsLightIntensity + (1.0 - insideSpot) * spotColor;
    else
        lightIntensity = fsLightIntensity;
    fragColor.rgb *= lightIntensity;
    fragColor.rgb += vec3(fsSpecularTerm, fsSpecularTerm, fsSpecularTerm);
    
    // Translucency (modulates existing alpha channel for RGBA4 texels)
    fragColor.a *= fsTransLevel;

    // Apply fog
    fragColor.rgb = mix(fragColor.rgb, gl_Fog.color.rgb, fsFogFactor);

    // Store final color
    gl_FragColor = fragColor;
}