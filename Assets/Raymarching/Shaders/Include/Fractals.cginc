#ifndef FRACTALS_H
#define FRACTALS_H

#include "./Utils.cginc"
#include "./Primitives.cginc"
//sampler2D _MainTex;
inline float RecursiveTetrahedron(float3 p, int loop)
{
   //// p = repeat(p / 2, 3.0); // What is this supposed to be??
    const float3 a1 = float3( 1.0,  1.0,  1.0);
    const float3 a2 = float3(-1.0, -1.0,  1.0);
    const float3 a3 = float3( 1.0, -1.0, -1.0);
    const float3 a4 = float3(-1.0,  1.0, -1.0);

    const float scale = 2.0;
    float d;
    for (int n = 0; n < loop; ++n) {
        float3 c = a1; 
        float minDist = length(p - a1);
        d = length(p - a2); if (d < minDist) { c = a2; minDist = d; }
        d = length(p - a3); if (d < minDist) { c = a3; minDist = d; }
        d = length(p - a4); if (d < minDist) { c = a4; minDist = d; }
        p = scale * p - c * (scale - 1.0);
    }
 
    return length(p) * pow(scale, float(-n));
}

inline float RecursiveTetrahedron2(float3 pos, int loop, float Scale)
{
    // combine even hex tiles and odd hex tiles
//   float Scale = 5.1;
   float3 a1 = float3(1,1,1);
   float3 a2 = float3 (-1,-1,1);
   float3 a3 = float3(1,-1,-1);
   float3 a4 = float3(-1,1,-1);
   float3 c;
   int n = 0;
   float dist, d;
   while(n<loop)
  {
     c=a1; dist = length(pos-a1);
     d=length(pos-a2); if (d<dist) {c=a2;dist=d; }
     d = length(pos-a3); if (d<dist){c = a3; dist=d;}
     d = length(pos-a4); if (d<dist) {c = a4; dist=d;}
     pos = Scale*pos-c*(Scale-1.0);
     n++;
    }	

    return length((pos)*pow(Scale,float(-n)));

}

inline float RecursiveFold(float3 p, int loop, float Scale)
{
    // combine even hex tiles and odd hex tiles
//   float Scale = 5.1;
   float3 a1 = float3(1,1,1);
   float3 a2 = float3 (-1,-1,1);
   float3 a3 = float3(1,-1,-1);
   float3 a4 = float3(-1,1,-1);
   float3 c;
   int n = 0;
   float dist, d;
   while(n<loop)
  {
     c=a1; dist = length(p-a1);
     d=length(p-a2); if (d<dist) {c=a2;dist=d; }
      if(p.x+p.y<0) p.xy = -p.yx; // fold 1
     d = length(p-a3); if (d<dist){c = a3; dist=d;}
      if(p.x+p.z<0) p.xz = -p.zx; // fold 2
     d = length(p-a4); if (d<dist) {c = a4; dist=d;}
      if(p.y+p.z<0) p.zy = -p.yz; // fold 3	
     p = Scale*p-c*(Scale-1.0);
     n++;
    }	

    return length((p)*pow(Scale,float(-n)));

}

inline float Fold(float3 p, int loop, float Scale)
{
		//float r;
   		int n = 0;
   		float3 Offset = float3(1,1,1);

    while (n < loop) 
    {
       if(p.x+p.y<0) p.xy = -p.yx; // fold 1
       if(p.x+p.z<0) p.xz = -p.zx; // fold 2
       if(p.y+p.z<0) p.zy = -p.yz; // fold 3	
       p = p*Scale - Offset*(Scale-1.0);
       n++;
    }
    return (length(p) ) * pow(Scale, -float(n));
}

float MandleBulb(float3 pos, int loop, float Power, float Bailout) {
	float3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < loop ; i++) 
	{
		r = length(z);
		if (r>Bailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan2(z.x,z.y);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
}

//float DodecaFractal(float3 z)
//{
//	// Fold:
//	//This is a folding set with dodecahedral symmetry
//	z = abs(z);
//	z-=2.0 * max(0.0, dot(z, n1)) * n1;//Thanks AndyAlias for the optimization
//	z-=2.0 * max(0.0, dot(z, n2)) * n2;
//	z = abs(z);
//	z-=2.0 * max(0.0, dot(z, n1)) * n1;
//	z-=2.0 * max(0.0, dot(z, n2)) * n2;
//	z = abs(z);
//	z-=2.0 * max(0.0, dot(z, n1)) * n1;
//	z-=2.0 * max(0.0, dot(z, n2)) * n2;
//
//	//Cut:
//	//Distance to the plane going through vec3(Size,0.,0.) and which normal is plnormal (must be normalized)
//	//You can also use curved and/or multiple cuts
//	return dot(z-float3(Size,0.,0.),plnormal);
//} 

inline float MengerSponge(float3 p, float s)
{
int n = 0;
for (n = 0; n < 10; n++)
   {
      p = abs(p);
      if (p.x < p.z) p.xz = p.zx;
      if (p.y < p.z) p.yz = p.zy;

      p.x = (s + 1.0) * p.x - s;
      p.y = (s + 1.0) * p.y - s;
      p.z = (s + 1.0) * p.z;

      if(p.z > 0.5 * s)  
         p.z -= s;

   }
   float dist = length(p) * pow(s + 1.0, float(-n)); 

   return dist;
}

//Another version of menger
inline float3 Menger( in float3 p, int loop, float scale)
{
   float d = Box(p,float3(scale,scale,0.5));

   float s = 1.0;
   for( int m=0; m<loop; m++ )
   {
      float3 a = myMod( p*s, 2.0 )-1.0;
      s *= 3.0;
      float3 r = abs(1.0 - 3.0*abs(a));

      float da = max(r.x,r.y);
      float db = max(r.y,r.z);
      float dc = max(r.z,r.x);
      float c = (min(da,min(db,dc))-1.0)/s;

      d = max(d,c);
   }
   float3 dist = float3(d,1.0,1.0);
   return dist;
}

  #endif



