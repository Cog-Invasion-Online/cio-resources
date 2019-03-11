/*
===========================================================================

Doom 3 BFG Edition GPL Source Code
Copyright (C) 2014 Robert Beckebans

This file is part of the Doom 3 BFG Edition GPL Source Code ("Doom 3 BFG Edition Source Code").  

Doom 3 BFG Edition Source Code is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Doom 3 BFG Edition Source Code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Doom 3 BFG Edition Source Code.  If not, see <http://www.gnu.org/licenses/>.

In addition, the Doom 3 BFG Edition Source Code is also subject to certain additional terms. You should have received a copy of these additional terms immediately following the terms and conditions of the GNU General Public License which accompanied the Doom 3 BFG Edition Source Code.  If not, please request a copy in writing from id Software at the address below.

If you have questions concerning this license or the applicable additional terms, you may contact in writing id Software LLC, c/o ZeniMax Media Inc., Suite 120, Rockville, Maryland 20850 USA.

===========================================================================
*/

const float PI = 3.14159265359;

float Distribution_GGX2(float HdotN, float roughness)
{
    float a = roughness*roughness;
    float a2 = a*a;
    float HdotN2 = HdotN*HdotN;
    
    float num = a2;
    float denom = (HdotN2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;
    
    return num / denom;
}

float GeometrySchlick_GGX(float NdotV, float roughness)
{
    float r = (roughness + 1.0);
    float k = (r*r) / 8.0;
    float num = NdotV;
    float denom = NdotV * (1.0 - k) + k;
    
    return num / denom;
}

float Geometry_Smith(float NdotV, float NdotL, float roughness)
{
    float ggx2 = GeometrySchlick_GGX(NdotV, roughness);
    float ggx1 = GeometrySchlick_GGX(NdotL, roughness);
    
    return ggx1 * ggx2;
}

// Normal Distribution Function ( NDF ) or D( h )
// GGX ( Trowbridge-Reitz )
float Distribution_GGX( float hdotN, float alpha )
{
	// alpha is assumed to be roughness^2
	float a2 = alpha * alpha;
	float tmp = ( hdotN * hdotN ) * ( a2 - 1.0 ) + 1.0;
	//float tmp = ( hdotN * a2 - hdotN ) * hdotN + 1.0;
	
	return ( a2 / ( PI * tmp * tmp ) );
}

float Distribution_GGX_Disney( float hdotN, float alphaG )
{
	float a2 = alphaG * alphaG;
	float tmp = ( hdotN * hdotN ) * ( a2 - 1.0 ) + 1.0;
	//tmp *= tmp;
	
	return ( a2 / ( PI * tmp ) );
}

float Distribution_GGX_1886( float hdotN, float alpha )
{
	// alpha is assumed to be roughness^2
	return ( alpha / ( PI * pow( hdotN * hdotN * ( alpha - 1.0 ) + 1.0, 2.0 ) ) );
}

// Fresnel term F( v, h )
// Fnone( v, h ) = F(0�) = specularColor
vec3 Fresnel_Schlick( vec3 specularColor, float vdotH )
{
	return specularColor + ( 1.0 - specularColor ) * pow( 1.0 - vdotH, 5.0 );
}

// Visibility term G( l, v, h )
// Very similar to Marmoset Toolbag 2 and gives almost the same results as Smith GGX
float Visibility_Schlick( float vdotN, float ldotN, float alpha )
{
	float k = alpha * 0.5;
	
	float schlickL = ( ldotN * ( 1.0 - k ) + k );
	float schlickV = ( vdotN * ( 1.0 - k ) + k );
	
	return ( 0.25 / ( schlickL * schlickV ) );
	//return ( ( schlickL * schlickV ) / ( 4.0 * vdotN * ldotN ) );
}

// see s2013_pbs_rad_notes.pdf
// Crafting a Next-Gen Material Pipeline for The Order: 1886
// this visibility function also provides some sort of back lighting
float Visibility_SmithGGX( float vdotN, float ldotN, float alpha )
{
	// alpha is already roughness^2

	float V1 = ldotN + sqrt( alpha + ( 1.0 - alpha ) * ldotN * ldotN );
	float V2 = vdotN + sqrt( alpha + ( 1.0 - alpha ) * vdotN * vdotN );
	
	// RB: avoid too bright spots
	return ( 1.0 / max( V1 * V2, 0.15 ) );
}


// Environment BRDF approximations
// see s2013_pbs_black_ops_2_notes.pdf
float a1vf( float g )
{
	return ( 0.25 * g + 0.75 );
}

float a004( float g, float vdotN )
{
	float t = min( 0.475 * g, exp2( -9.28 * vdotN ) );
	return ( t + 0.0275 ) * g + 0.015;
}

float a0r( float g, float vdotN )
{
	return ( ( a004( g, vdotN ) - a1vf( g ) * 0.04 ) / 0.96 );
}

vec3 EnvironmentBRDF( float g, float vdotN, vec3 rf0 )
{
	vec4 t = vec4( 1.0 / 0.96, 0.475, ( 0.0275 - 0.25 * 0.04 ) / 0.96, 0.25 );
	t *= vec4( g, g, g, g );
	t += vec4( 0.0, 0.0, ( 0.015 - 0.75 * 0.04 ) / 0.96, 0.75 );
	float a0 = t.x * min( t.y, exp2( -9.28 * vdotN ) ) + t.z;
	float a1 = t.w;
	
	return clamp( a0 + rf0 * ( a1 - a0 ), 0, 1 );
}


vec3 EnvironmentBRDFApprox( float roughness, float vdotN, vec3 specularColor )
{
	const vec4 c0 = vec4( -1, -0.0275, -0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, -0.04 );

	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( -9.28 * vdotN ) ) * r.x + r.y;
	vec2 AB = vec2( -1.04, 1.04 ) * a004 + r.zw;

	return specularColor * AB.x + AB.y;

}


