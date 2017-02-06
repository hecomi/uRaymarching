#ifndef TILES2D_H
#define TILES2D_H

/// Persistence of Vision Ray Tracer ('POV-Ray') version 3.7.
/// Copyright 1991-2016 Persistence of Vision Raytracer Pty. Ltd.
///
/// POV-Ray is free software: you can redistribute it and/or modify
/// it under the terms of the GNU Affero General Public License as
/// published by the Free Software Foundation, either version 3 of the
/// License, or (at your option) any later version.
///
/// POV-Ray is distributed in the hope that it will be useful,
/// but WITHOUT ANY WARRANTY; without even the implied warranty of
/// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
/// GNU Affero General Public License for more details.
///
/// You should have received a copy of the GNU Affero General Public License
/// along with this program.  If not, see <http://www.gnu.org/licenses/>.
///
/// ----------------------------------------------------------------------------
///
/// POV-Ray is based on the popular DKB raytracer version 2.12.
/// DKBTrace was originally written by David K. Buck.
/// DKBTrace Ver 2.0-2.12 were written by David K. Buck & Aaron A. Collins.
  


// ----- Interface -----
//
//   pov_tiling*() functions return
//     x: distance to inside, outside = 1.
//    y: shape index 0-2 (when there are different shapes in one pattern)
//

float2 pov_tiling_square(in float2 p);
float2 pov_tiling_square_offset(in float2 p);
float2 pov_tiling_hexagon(in float2 p);
float2 pov_tiling_triangle(in float2 p);
float2 pov_tiling_lozenge(in float2 p);
float2 pov_tiling_rhombus(in float2 p);
float2 pov_tiling_rectangle(in float2 p);
float2 pov_tiling_octa_square(in float2 p);
float2 pov_tiling_square_triangle(in float2 p);
float2 pov_tiling_hexa_triangle(in float2 p);

///* One function to get all, pattern = 0-9 */
inline float2 pov_tiling(in float2 p, in int pattern)
{
	if (pattern == 0) return pov_tiling_square(p);
	if (pattern == 1) return pov_tiling_square_offset(p);
	if (pattern == 2) return pov_tiling_hexagon(p);
	if (pattern == 3) return pov_tiling_triangle(p);
	if (pattern == 4) return pov_tiling_lozenge(p);
	if (pattern == 5) return pov_tiling_rhombus(p);
	if (pattern == 6) return pov_tiling_rectangle(p);
	if (pattern == 7) return pov_tiling_octa_square(p);
	if (pattern == 8) return pov_tiling_square_triangle(p);
	if (pattern == 9) return pov_tiling_hexa_triangle(p);
	return float2(-1, 0.);
}


// ########################## IMPLEMENTATION ###########################

#define POV_SQRT3_2     0.86602540378443864676372317075294  ///< sqrt(3)/2
#define POV_SQRT3       1.7320508075688772935274463415059   ///< sqrt(3)
#define POV_SQRT2       1.4142135623730950488016887242097   ///< sqrt(2)
#define POV_SQRT2_2     0.70710678118654752440084436210485  ///< sqrt(2)/2

float2 pov_tiling_square(in float2 p)
{
    p = abs(p);
	float2 x = p - floor(p);
	x = 2. * abs(x - .5);
	return float2(max(x.x, x.y), 0.);
}

float2 pov_tiling_hexagon(in float2 p)
{
	float2 x = p;
	x.x += 0.5;
	x.x -= 3.0*floor(x.x/3.0);
	x.y -= POV_SQRT3*floor(x.y/POV_SQRT3);
//	/* x,z is in { [0.0, 3.0 [, [0.0, SQRT3 [ } 
//	 ** but there is some symmetry to simplify the testing
//	 */
	if (x.y > POV_SQRT3_2)
		x.y = POV_SQRT3 - x.y;
	/* 
	 ** Now only [0,3[,[0,SQRT3/2[
	 */
	if (x.x > 1.5)
	{
		x.x -= 1.5; /* translate */
		x.y = POV_SQRT3_2 - x.y; /* mirror */
	}
//	/*
//	 ** And now, it is even simpler :  [0,1.5],[0,SQRT3/2]
//	 ** on the bottom left corner, part of some other hexagon
//	 ** on the top right corner, center of the hexagon
//	 */
	if ((POV_SQRT3*x.x + x.y) < POV_SQRT3_2)
	{
		x.x = 0.5 - x.x;
		x.y = POV_SQRT3_2 - x.y; /* mirror */
	}
	if (x.x > 1.0)
	{
		x.x = 2.0 - x.x; /* mirror */
	}
	/* Hexagon */
	return float2(clamp(
				max(1. - x.y / POV_SQRT3_2,
                    1. - ((POV_SQRT3 * x.x + x.y - POV_SQRT3_2) / POV_SQRT3)
				), 0., 1.), 0.);
}

float2 pov_tiling_triangle(in float2 p)
{
	float2 x = p;
	x.x -= floor(x.x);
	x.y -= POV_SQRT3 * floor(x.y/POV_SQRT3);
	float delta = 0.;
//	/* x,z is in { [0.0, 1.0 [, [0.0, SQRT3 [ } 
//	 ** but there is some symmetry to simplify the testing
//	 */
	if (x.y > POV_SQRT3_2)
	{
		x.y = POV_SQRT3 - x.y; /* mirror */
		delta = 1.-delta;
	}
	if (x.x > 0.5)
	{
		x.x = 1.0 - x.x; /* mirror */
	}
	if (x.x != 0.0)
	{
		float slop1 = x.y / x.x;
		if (slop1 > POV_SQRT3)
		{
			x.y = POV_SQRT3_2 - x.y;
			x.x = 0.5 - x.x;
			delta = 1.-delta;
		}
	}
	else
	{
		x.y = POV_SQRT3_2 - x.y;
		x.x = 0.5;
	}
	float d1 = 1. - (x.y * 2. * POV_SQRT3);
	float d2 = 1. - ((POV_SQRT3 * x.x - x.y) * POV_SQRT3);
	return float2(max(d1, d2), delta);
//	return delta>.5 ? max(d1, d2)*.5 : 1.-.5*max(d1, d2); 
	// XXX original, not sure if this is right??
	//return delta*.5 + .5 * max(d1, d2);
}

float2 pov_tiling_lozenge(in float2 p)
{
	float2 x = p;
	x.x -= floor(x.x);
	x.y -= POV_SQRT3*floor(x.y/POV_SQRT3);
//	/* x,z is in { [0.0, 1.0 [, [0.0, SQRT3 [ } 
//	 ** There is some mirror to reduce the problem
//	 */
	if (x.y > POV_SQRT3_2)
	{
		x.y -= POV_SQRT3_2;
		x.x += 0.5;
	}
	if ((2.*x.y) > POV_SQRT3_2)
	{
		x.y = POV_SQRT3_2 - x.y;
		x.x = 1.5 - x.x;
	}
	if (x.x > 0.75)
	{
		x.x -= 1.0;
	}
	if (x.x != 0.0)
	{
		float slop1 = x.y / x.y;
		if (slop1 > POV_SQRT3)
		{
			x.y = POV_SQRT3_2 - x.y;
			x.x = 0.5 - x.x;
		}
	}
	float d1 = 1.0 - (x.y * 4.0 * POV_SQRT3 / 3.0 );
	float d2 = 1.0 - (abs(POV_SQRT3 * x.x - x.y) * POV_SQRT3 * 2.0 / 3.0);
	return float2(max(d1, d2), 0.);
}

float2 pov_tiling_rhombus(in float2 p)
{
	float x = p.x, z = p.y, delta = 0.;
	x += 0.5;
	x -= 3.0*floor(x/3.0);
	z -= POV_SQRT3*floor(z/POV_SQRT3);
//	/* x,z is in { [0.0, 3.0 [, [0.0, SQRT3 [ } 
//	 ** There is some mirror to reduce the problem
//	 */
	if ( z > POV_SQRT3_2 )
	{
		z = POV_SQRT3 -z; /* mirror */
		delta = 2. - delta;
	}
	if (x > 1.5)
	{
		x -= 1.5 ; /* translate */
		z = POV_SQRT3_2 -z; /* mirror */
		delta = 2. - delta;
	}
//	/* Now in [0,1.5],[0,SQRT3/2] 
//	 ** from left to right
//	 ** part of a horizontal (z=0)
//	 ** half a vertical 
//	 ** part of a horizontal 
//	 */
	if (x < 0.5)
	{
		//* mirrror */
		x = 1.0 - x;
		delta = 2. - delta;
	}
//	/* 
//	 ** Let shift the [0.5,1.5],[0,SQRT3/2] to [0,1]....
//	 */
	x -= 0.5;
	if (x != 0.0)
	{
		float slop1 = z/x;
		if (slop1>POV_SQRT3)
		{ /* rotate the vertical to match the horizontal on the right */
			float dist1 = ( x / 2.0 ) + ( z * POV_SQRT3_2 );
			float dist2 = ( z / 2.0 ) - ( x * POV_SQRT3_2 );
			z = dist2;
			x = dist1;
			delta = 1.;
		}
	}
	else
	{
		/* rotate the vertical to match the horizontal on the right */
		float dist1 = ( x / 2.0 ) + ( z * POV_SQRT3_2 );
		float dist2 = ( z / 2.0 ) - ( x * POV_SQRT3_2 );
		z = dist2;
		x = dist1;
		delta = 1.;
	}
	///* It may be similar to lozenge (in fact, IT IS !), now */

	if ( (2.0*z) > POV_SQRT3_2 )
	{
		z = POV_SQRT3_2 - z;
		x = 1.5 - x;
	}
	if (x > 0.75)
	{
		x -= 1.0;
	}
	if (x != 0.0)
	{
		float slop1 = z / x;
		if (slop1 > POV_SQRT3)
		{
			z = POV_SQRT3_2 - z;
			x = 0.5 -x;
		}
	}
	float d1 = 1.0 - (z * 4.0 * POV_SQRT3 / 3.0 );
	float d2 = 1.0 - (abs(POV_SQRT3 * x - z) * POV_SQRT3 *2.0 / 3.0);
	return float2(clamp(max(d1, d2), 0., 1.), delta);
	// original
	//return clamp( (max(d1, d2) + delta) / 3., 0., 1.);
}

float2 pov_tiling_rectangle(in float2 po)
{
//	/*
//	 ** Tiling with rectangles
//	 ** resolve to square [0,4][0,4]
//	 ** then 16 cases
//	 **
//	 **  +-----+--+  +
//	 **  |     |  |  |
//	 **  +--+--+  +--+
//	 **     |  |  |
//	 **  +--+  +--+--+
//	 **  |  |  |     |
//	 **  +  +--+--+--+
//	 **  |  |     |  |
//	 **  +--+-----+  +
//	 */
	float x = po.x, z = po.y, 
		  delta = 1.;
	x -= 4.0*floor(x/4.0);
	z -= 4.0*floor(z/4.0);
    int idx = int(x) + 4*int(z);
	if (idx == 0 || idx == 4)
		z -= 1.0;
    if (idx == 1 || idx == 2)
		x -= 2.0, delta = 0.0;
	if (idx == 3)
		x -= 3.0;
	if (idx == 5 || idx == 9)
		x -= 1.0, z -= 2.0;
	if (idx == 6 || idx == 7)
		x -= 3.0, z -= 1.0, delta = 0.0;
    if (idx == 8)
		z -= 2.0, delta = 0.0;
	if (idx == 10 || idx == 14)
		x -= 2.0, z -= 3.0;
	if (idx == 11)
		x -= 4.0, z -= 2.0, delta = 0.0;
	if (idx == 12 || idx == 13)
		x -= 1.0, z -= 3.0, delta = 0.0;
	if (idx == 15)
		x -= 3.0, z -= 4.0;

    if (delta >= 1.0)
	{
		x = 2.*abs(x - 0.5);
		z = 2.*(max(abs(z), 0.5) - 0.5);
	}
	else
	{
		x = 2.*(max(abs(x), 0.5) - 0.5);
		z = 2.*abs(z - 0.5);
	}
	return float2(max(x, z), delta);
//	return delta>.5 ? max(x, z)*.5 : 1.-.5*max(x, z); 
	// XXX original
//	return abs(max(x, z) + delta) / 2.;
}


float2 pov_tiling_octa_square (in float2 p)
{
//	/*
//	 ** Tiling with a square and an octagon
//	 */
	float2 x = p;
	x -= (POV_SQRT2+1.0) * floor(x/(POV_SQRT2+1.0));
	x -= POV_SQRT2_2 + 0.5;
	x = abs(x);
	if (x.y > x.x)
		x = x.yx;
	if ((x.x+x.y) < POV_SQRT2_2)
	{
		/* Square tile */
		return float2((x.x+x.y) / POV_SQRT2, 0.);
	}
	float dist1 = 1.0-x.y;
	float dist2 = (POV_SQRT2 + POV_SQRT2_2-(x.x+x.y))/POV_SQRT2;
	return float2(max(0., 0.19+.81*max(dist1,dist2)), 1.); 
}

float2 pov_tiling_square_triangle(in float2 p)
{
	float x = p.x, z = p.y, delta = 0.;
	x -= floor(x);
	z -= (2.0+POV_SQRT3)*floor(z/(POV_SQRT3+2.0));
//	/* x,z is in { [0.0, 1.0 [, [0.0, 2+SQRT3 [ } 
//	 ** but there is some symmetry to simplify the testing
//	 */
	if (z > POV_SQRT3_2+1.0 )
	{
		z -= POV_SQRT3_2+1.0;
		x += (x>0.5)?-0.5:0.5;
	}
	if (x > 0.5)
	{
		x = 1.0 - x; /* mirror */
	}
	z -= 1.0;
	if (z > 0.0)
	{ /* triangle */
		if (x != 0.0)
		{
			if (z/x > POV_SQRT3)
			{
				z = POV_SQRT3_2 - z;
				x = 0.5 - x;
				delta = 1. - delta;
			}
		}
		else
		{
			z = POV_SQRT3_2 - z;
			x = 0.5;
			delta = 1. - delta;
		}
		float dist1 = 1.0 - (2. * z * POV_SQRT3);
		float dist2 = 1.0 - ((POV_SQRT3 * x - z) * POV_SQRT3);
		return float2(max(dist1, dist2), delta);
	}
	else
	{ /* square */
		if (z < -0.5)
		{
			z = -1.0 - z;
		}
		if (x > 0.5)
		{
			x = 1.0 - x;
		}
		return float2((1.000000-2.*min(abs(x),abs(z))), 2.);
	}
}

float2 pov_tiling_hexa_triangle(in float2 p)
{
//	/* 
//	 ** Tiling with a hexagon and 2 triangles
//	 */
	float x = p.x, z = p.y, delta = 0.;
	x -= 2.0*floor(x/2.0);
	z -= 2.0*POV_SQRT3*floor(z/(POV_SQRT3*2.0));
//	/* x,z is in { [0.0, 2.0 [, [0.0, 2*SQRT3 [ } 
//	 ** but there is some symmetry to simplify the testing
//	 */
	if (z > POV_SQRT3)
	{
		z -= POV_SQRT3;
		x += (x<1.0)?1.0:-1.0;
	}
//	/* 
//	 ** Now only [0,2[,[0,SQRT3[
//	 */
	if (z > POV_SQRT3_2)
	{
		z = POV_SQRT3 - z; /* mirror */
		delta = 1. - delta;
	}

	if (x > 1.0)
	{
		x = 2.0 - x; /* mirror */
	}
//	/*
//	 ** And now, it is even simpler :  [0,1],[0,SQRT3/2]
//	 ** on the bottom left corner, part of the triangle
//	 ** on the top right corner, center of the hexagon
//	 */
	if ((POV_SQRT3*x+z)<POV_SQRT3_2)
	{
		//* Triangle */
		float dist1 = 1.0 - (z * 2. * POV_SQRT3);
		float dist2 = 1.0 + ((POV_SQRT3 * x + z) - POV_SQRT3_2) * POV_SQRT3; 
			/*< really substracting */
		return float2(max(dist1,dist2), delta);
	}
	else
	{
		//* Hexagon */
		float dist1 = 2. + 2. * (z * POV_SQRT3);
		float dist2 = 2. + 2. * ((POV_SQRT3 * x + z - POV_SQRT3_2) ) * POV_SQRT3_2;
		return float2((5.0-min(dist1,dist2)) / 3., 2.);
		// TODO FIXME - magic number! Should use nextafter()
	}
}

float2 pov_tiling_square_offset(in float2 p)
{
//	/*
//	 ** Tiling with a square, offset of half size
//	 ** Reduce to rectangle [0,1][0,2]
//	 ** move x,[1,2] to [0,1][0,1] with new x = x+1/2
//	 */
	float2 x = float2(p.x, p.y - 2.*floor(p.y/2.));
	if (x.y > 1.0)
	{
		x.x += 0.5;
		x.y -= 1.;
	}
	x.x -= floor(x.x);
	x = 2.*abs(x-0.5);
	return float2(max(x.x, x.y), 0.);
}

// #################################################################



float hash1(in float2 p) { return frac(sin(p.x+p.y)*(73481.+p.x*1.3-p.y*1.7)); }

inline float2 TileMove(in float2 uv, in float time, float scale, int pattern)
{
    //int   pattern = ;
    //float soft = hash1(scale++); soft *= soft * soft;
  //  float thick = 0.01 + .1*hash1(scale++);
   // float scale = 2. + 5. * hash1(seed++);
            
    //uv += 0.2*time*float2(hash1(scale++)-.5, hash1(scale++)-.5);
    float2 tile = pov_tiling(uv*scale, pattern);
    tile.y = 5.0*sin(time*1.0);
   // float3 col = float3(0.5+.5*cos(hash1(scale++)*float3(1.7+uv.y,1.1+uv.x,2.1)*6.*hash1(scale++)));

   // float rep = .2 + (1.-thick) * .8 * hash1(scale++ + tile.y);
    //tile.x = tile.x*sin(time*0.5);
    //col *= smoothstep(soft+0.015*scale, .0, abs(tile.x)-thick);

    return tile;
}

inline float2 TileMoveCol(in float2 uv, in float2 seed, float time, int pattern, float scale)
{
    //int   pattern = ;
    //float time = _Time.y;
   // float scale = 0;
    float soft = hash1(seed++); soft *= soft * soft;
    float thick = 0.01 + .1*hash1(seed++);
   // scale = 2. + 5. * hash1(scale++);
            
    uv += 0.2*time*float2(hash1(seed++)-.5, hash1(seed++)-.5);
    float2 tile = pov_tiling(uv*scale, pattern);
    //tile.y = 5.0*sin(time*1.0);
    float3 col = float3(0.5+.5*cos(hash1(seed++)*float3(1.7+uv.y,1.1+uv.x,2.1)*6.*hash1(seed++)));

    float rep = .2 + (1.-thick) * .8 * hash1(seed++ + tile.y);
   // tile.x = tile.x*sin(time*0.5);
    col *= smoothstep(soft+0.015*scale, .0, abs(tile.x)-thick);

    if (hash1(seed) > .6)
    	col = 1. - col;

    //uv.x = ctrl;

    return col;
}

#endif
