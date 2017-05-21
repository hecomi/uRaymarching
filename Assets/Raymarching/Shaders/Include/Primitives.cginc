#ifndef PRIMITIVES_H
#define PRIMITIVES_H
#include "./DomainOperators.cginc"
#define PI 3.14159265
#define TAU (2*PI)
#define PHI (sqrt(5)*0.5 + 0.5)

#define saturate(x) clamp(x, 0, 1)
#define myMod(x,y) (x-y*floor(x/y))

// Most of these are ported from Mercury's sdf database, converted from GLSL to HLSL, not all have been tested...

float square (float x) {
	return x*x;
}

float2 square (float2 x) {
	return x*x;
}

float3 square (float3 x) {
	return x*x;
}

float lengthSqr(float3 x) {
	return dot(x, x);
}

float vmax(float2 v) {
	return max(v.x, v.y);
}

float vmax(float3 v) {
	return max(max(v.x, v.y), v.z);
}

float vmax(float4 v) {
	return max(max(v.x, v.y), max(v.z, v.w));
}

float vmin(float2 v) {
	return min(v.x, v.y);
}

float vmin(float3 v) {
	return min(min(v.x, v.y), v.z);
}

float vmin(float4 v) {
	return min(min(v.x, v.y), min(v.z, v.w));
}
float3 RotateX(float3 v, float rad)
{
  float Cos = cos(rad);
  float Sin = sin(rad);
  return float3(v.x, Cos * v.y + Sin * v.z, -Sin * v.y + Cos * v.z);
}
float3 RotateY(float3 v, float rad)
{
  float Cos = cos(rad);
  float Sin = sin(rad);
  return float3(Cos * v.x - Sin * v.z, v.y, Sin * v.x + Cos * v.z);
}
float3 RotateZ(float3 v, float rad)
{
  float Cos = cos(rad);
  float Sin = sin(rad);
  return float3(Cos * v.x + Sin * v.y, -Sin * v.x + Cos * v.y, v.z);
}

inline float Sphere(float3 pos, float radius)
{
    return length(pos) - radius;
}

inline float RoundBox(float3 pos, float3 size, float round)
{
    return length(max(abs(pos) - size, 0.0)) - round;
}

inline float Box(float3 pos, float3 size)
{
    // complete box (round = 0.0) cannot provide high-precision normals.
    return RoundBox(pos, size, 0.0001);
}

inline float Torus(float3 pos, float2 radius)
{
    float2 r = float2(length(pos.xy) - radius.x, pos.z);
    return length(r) - radius.y;
}

inline float Plane(float3 pos, float3 dir)
{
    return dot(pos, dir);
}

inline float Corner (float2 p) {
	return length(max(p, float2(0,0))) + vmax(min(p, float2(0,0)));
}

// really useful ring, r = inner radius, or = outerRadius, h = height of ring
inline float Rings (float3 p, float r, float or, float h)
{
	return max(abs(length(p.xz)-r)-or,abs(p.y)-h);
}

inline float PolarPlace (float3 p)
{
  float3 rad = 4.0*floor(myMod(length(p),128.0)-64.0*myMod(normalize(p),0.1));

  float dist = Box(rad, 0.1);
  return dist;
}

inline float MetaBalls3 (float3 p, float q, float r)
{
	float m1 = Sphere( p,  0.1);
	float m2 = Sphere( p,  0.3);
	float m3 = Sphere( p,  0.5);
	float e = 0.2;

	float srf = 1.0/(m1+q+e)+1.0/(m2+q+e)+1.0/(m3+q+e);

    float dstrf = 1.0/srf - (r);

	return dstrf; 
}

inline float Blob(float3 p) {
	p = abs(p);
	if (p.x < max(p.y, p.z)) p = p.yzx;
	if (p.x < max(p.y, p.z)) p = p.yzx;
	float b = max(max(max(
		dot(p, normalize(float3(1, 1, 1))),
		dot(p.xz, normalize(float2(PHI+1, 1)))),
		dot(p.yx, normalize(float2(1, PHI)))),
		dot(p.xz, normalize(float2(1, PHI))));
	float l = length(p);
	return l - 1.5 - 0.2 * (1.5 / 2)* cos(min(sqrt(1.01 - b / l)*(PI / 0.25), PI));
}

// Distance to line segment between <a> and <b>, used for fCapsule() version 2below
inline float LineSegment(float3 p, float3 a, float3 b) {
	float3 ab = b - a;
	float t = saturate(dot(p - a, ab) / dot(ab, ab));
	return length((ab*t + a) - p);
}

// Capsule version 2: between two end points <a> and <b> with radius r 
inline float Capsule(float3 p, float3 a, float3 b, float r) {
	return LineSegment(p, a, b) - r;
}

inline float Disc(float3 p, float r) {
	float l = length(p.xz) - r;
	return l < 0 ? abs(p.y) : length(float2(p.y, l));
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return lerp( b, a, h ) - k*h*(1.0-h);
}

inline float DiscRing(float3 p, float r, float scale, float thickness) 
{
	float l = length(p.xz) - r;
	float dist = l - scale;
	dist = max(dist, -(l-0.85*scale));
	dist = -smin(-dist,-(abs(p.y)-thickness),0.015*scale);

	return dist;
	//return l < 0 ? abs(p.y) : length(float2(p.y, l));
}

float2 DiscObjects(float3 p, float time, float thickness)
{
    float spinTime = 0.0;
    float rampStep = 0.0;
//    rampStep = min(1.0,max(1.0, abs((frac(localTime)-0.5)*1.0)*8.0))*0.5-0.5;
    rampStep = smoothstep(0.0, 1.0, rampStep);
    // lopsided triangle wave - goes up for 3 time units, down for 1.
    float step31 = (max(0.0, (frac(time+0.125)-0.25)) - min(0.0,(frac(time+0.125)-0.25))*3.0)*0.333;
    spinTime = step31 + time - 0.125;

    float dist = 1000000.0;
    float currentThick = 6.0;
    float thick = 0.94;
    float spacer = 0.14;
    float harmonicTime = spinTime*0.125*3.14159*8.0;
    float thickSpace;
    thickSpace = thick - spacer;
    // make 15 discs inside each other
    for (int i = 0; i < 9; i++)
    {
        dist = min(dist, DiscRing(p, 0.05,currentThick, thickness));
        p = RotateY(p, harmonicTime);
        p = RotateZ(p, harmonicTime);
        // scale down a level
        currentThick *= thick - spacer;
    }
    float2 distMat = float2(dist, 0.0);
    // ball in center
   // distMat = matMin(distMat, float2(length(p) - 0.45, 6.0));
    return distMat;
}

inline float Cylinder(float3 pos, float2 r)
{
    float2 d = abs(float2(length(pos.xy), pos.z)) - r;
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - 0.1;
}

float fCylinder(float3 p, float r, float height) 
{
	float d = length(p.xy) - r; // xy and xz give cool results
	d = max(d, abs(p.z) - height);
	return d;
}

inline float HexagonalPrismX(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.x - h.y, 
        max(
            (p.z * 0.866025 + p.y * 0.5),
            p.y
        ) - h.x
    );
}

inline float Cone(float3 p, float radius, float height) {
	float2 q = float2(length(p.xz), p.y);
	float2 tip = q - float2(0, height);
	float2 mantleDir = normalize(float2(height, radius));
	float mantle = dot(tip, mantleDir);
	float d = max(mantle, -q.y);
	float projected = dot(tip, float2(mantleDir.y, -mantleDir.x));
	
	// distance to tip
	if ((q.y > height) && (projected < 0)) {
		d = max(d, length(tip));
	}
	
	// distance to base ring
	if ((q.x > radius) && (projected > length(float2(height, radius)))) {
		d = max(d, length(q - float2(radius, 0)));
	}
	return d;
}

// Hexagonal prism, circumcircle variant
inline float HexagonCircumcircle(float3 p, float2 h) {
	float3 q = abs(p);
	return max(q.y - h.y, max(q.x*sqrt(3)*0.5 + q.z*0.5, q.z) - h.x);
	//this is mathematically equivalent to this line, but less efficient:
	//return max(q.y - h.y, max(dot(float2(cos(PI/3), sin(PI/3)), q.zx), q.z) - h.x);
}

// Hexagonal prism, incircle variant
inline float HexagonIncircle(float3 p, float2 h) {
	return HexagonCircumcircle(p, float2(h.x*sqrt(3)*0.5, h.y));
}


inline float HexagonalPrismY(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.y - h.y, 
        max(
            (p.z * 0.866025 + p.x * 0.5),
            p.x
        ) - h.x
    );
}

inline float HexagonalPrismZ(float3 pos, float2 h)
{
    float3 p = abs(pos);
    return max(
        p.z - h.y, 
        max(
            (p.x * 0.866025 + p.y * 0.5),
            p.y
        ) - h.x
    );
}
		int Type=2;
		float U=0.0;
		float V=0.0;
		float W=1.0;
		const float SRadius=0.03; 
		const float VRadius=0.07;

	    float3 nc;
	    //float3 p;
	    float3 pab;
	    float3 pbc;
	    float3 pca;
	//setup folding planes and vertex
	    //Type=float
 float3 getP()
   {
   		float t=_Time.y;
   	    U = 0.5*sin(t*1.5)+0.5;
	    V = (0.5*sin(t*0.8)+0.5);
	    W = (0.5*sin(t*0.3)+0.5);
	    float cospin=cos(PI/float((frac(0.025*t)*3.)+3)), scospin=sqrt(0.75-cospin*cospin);
        nc = float3(-0.5,-cospin,scospin);//3rd folding plane. The two others are xz and yz planes
		pab = float3(0.,0.,1.);
		pbc = float3(scospin,0.,0.5);//No normalization in order to have 'barycentric' coordinates work evenly
		pca = float3(0.,scospin,cospin);
		float3 p = normalize((U*pab+V*pbc+W*pca));
        return p; 
   }

	float3 fold(float3 pos) 
	{
	   float t=_Time.y;
	   float cospin=cos(PI/float((frac(0.025*t)*3.)+3)), scospin=sqrt(0.75-cospin*cospin);
       nc = float3(-0.5,-cospin,scospin);//3rd folding plane. The two others are xz and yz planes

		for(int i=0;i<5 /*Type*/;i++){
			pos.xy=abs(pos.xy);//fold about xz and yz planes
			pos-=2.*min(0.,dot(pos,nc))*nc;//fold about nc plane
		}
		return pos;
	}

	float D2Planes(float3 pos) 
	{
		float3 p = getP();
		pos-=p;
	    float d0=dot(pos,pab);
		float d1=dot(pos,pbc);
		float d2=dot(pos,pca);
		return max(max(d0,d1),d2);
	}

	float length2(float3 p){ 
	return dot(p,p);
	}

	float D2Segments(float3 pos) 
	{
	    float3 p = getP();
	    float t = _Time.y;
	    float cospin=cos(PI/float((frac(0.025*t)*3.)+3)), scospin=sqrt(0.75-cospin*cospin);
        nc = float3(-0.5,-cospin,scospin);//3rd folding plane. The two others are xz and yz planes
		pos-=p;
		float dla=length2(pos-min(0.,pos.x)*float3(1.,0.,0.));
		float dlb=length2(pos-min(0.,pos.y)*float3(0.,1.,0.));
		float dlc=length2(pos-min(0.,dot(pos,nc))*nc);
		return sqrt(min(min(dla,dlb),dlc))-SRadius;
	}

	float D2Vertices(float3 pos) 
	{
	    float3 p = getP();
		return length(pos-p)-VRadius;
	}
	  
	float Polyhedron(float3 pos) 
	{
		pos=fold(pos);
		float d=10000.;
		d=min(d,D2Planes(pos));
		d=min(d,D2Segments(pos));
		d=min(d,D2Vertices(pos));
		return d;
	}
//"For higher values of e (>~50) it seems to be kinda "unstable". 
// could take limits directly, haven't cahnged them yet
//ie...
// s = abs(dot(p, n4));
// s = max(s, abs(dot(p, n5)));
// s = max(s, abs(dot(p, n6)));
  // ...
//  return s-r;

// I've tried a few differnt ways to get all the primitves icos/doced into Unity, but haven't been able to crack it yet, closest is 
//Polyhedron above

float3 n1 = float3(1.000,0.000,0.000);
float3 n2 = float3(0.000,1.000,0.000);
float3 n3 = float3(0.000,0.000,1.000);
float3 n4 = float3(0.577,0.577,0.577);
float3 n5 = float3(-0.577,0.577,0.577);
float3 n6 = float3(0.577,-0.577,0.577);
float3 n7 = float3(0.577,0.577,-0.577);
float3 n8 = float3(0.000,0.357,0.934);
float3 n9 = float3(0.000,-0.357,0.934);
float3 n10 = float3(0.934,0.000,0.357);
float3 n11 = float3(-0.934,0.000,0.357);
float3 n12 = float3(0.357,0.934,0.000);
float3 n13 = float3(-0.357,0.934,0.000);
float3 n14 = float3(0.000,0.851,0.526);
float3 n15 = float3(0.000,-0.851,0.526);
float3 n16 = float3(0.526,0.000,0.851);
float3 n17 = float3(-0.526,0.000,0.851);
float3 n18 = float3(0.851,0.526,0.000);
float3 n19 = float3(-0.851,0.526,0.000);

// p as usual, e exponent (p in the paper), r radius or something like that
inline float Octohedron2(float3 p, float e, float r) {
	float s = pow(abs(dot(p,n4)),e);
	s += pow(abs(dot(p,n5)),e);
	s += pow(abs(dot(p,n6)),e);
	s += pow(abs(dot(p,n7)),e);
	s = pow(s, 1./e);
	return s-r;
}


inline float Dodecahedron(float3 p, float e, float r) {
	float s = pow(abs(dot(p,n14)),e);
	s += pow(abs(dot(p,n15)),e);
	s += pow(abs(dot(p,n16)),e);
	s += pow(abs(dot(p,n17)),e);
	s += pow(abs(dot(p,n18)),e);
	s += pow(abs(dot(p,n19)),e);
	s = pow(s, 1./e);
	return s-r;
}

inline float Icosohedron(float3 p, float e, float r) {
	float s = pow(abs(dot(p,n4)),e);
	s += pow(abs(dot(p,n5)),e);
	s += pow(abs(dot(p,n6)),e);
	s += pow(abs(dot(p,n7)),e);
	s += pow(abs(dot(p,n8)),e);
	s += pow(abs(dot(p,n9)),e);
	s += pow(abs(dot(p,n10)),e);
	s += pow(abs(dot(p,n11)),e);
	s += pow(abs(dot(p,n12)),e);
	s += pow(abs(dot(p,n13)),e);
	s = pow(s, 1./e);
	return s-r;
}

float TruncatedOctahedron(float3 p, float e, float r) {
	float s = pow(abs(dot(p,n1)),e);
	s += pow(abs(dot(p,n2)),e);
	s += pow(abs(dot(p,n3)),e);
	s += pow(abs(dot(p,n4)),e);
	s += pow(abs(dot(p,n5)),e);
	s += pow(abs(dot(p,n6)),e);
	s += pow(abs(dot(p,n7)),e);
	s = pow(s, 1./e);
	return s-r;
}

float TruncatedIcosohedron(float3 p, float e, float r) {
	float s = pow(abs(dot(p,n4)),e);
	s += pow(abs(dot(p,n5)),e);
	s += pow(abs(dot(p,n6)),e);
	s += pow(abs(dot(p,n7)),e);
	s += pow(abs(dot(p,n8)),e);
	s += pow(abs(dot(p,n9)),e);
	s += pow(abs(dot(p,n10)),e);
	s += pow(abs(dot(p,n11)),e);
	s += pow(abs(dot(p,n12)),e);
	s += pow(abs(dot(p,n13)),e);
	s += pow(abs(dot(p,n14)),e);
	s += pow(abs(dot(p,n15)),e);
	s += pow(abs(dot(p,n16)),e);
	s += pow(abs(dot(p,n17)),e);
	s += pow(abs(dot(p,n18)),e);
	s += pow(abs(dot(p,n19)),e);
	s = pow(s, 1./e);
	return s-r;
}

float tOctahedral(float3 p, float r) {
	float s = abs(dot(p,n1));
	s = max(s,abs(dot(p,n2)));
	s = max(s,abs(dot(p,n3)));
	s = max(s,abs(dot(p,n4)));
	s = max(s,abs(dot(p,n5)));
	s = max(s,abs(dot(p,n6)));
	s = max(s,abs(dot(p,n7)));
	return s-r;
}
// Couldn't get these to work properly, could be glsl/hlsl differnences, or the swichthing in phi and ints
 float3 GDFVectors[19] = 
{
	normalize(float3(1, 0, 0)),
	normalize(float3(0, 1, 0)),
	normalize(float3(0, 0, 1)),

	normalize(float3(1, 1, 1 )),
	normalize(float3(-1, 1, 1)),
	normalize(float3(1, -1, 1)),
	normalize(float3(1, 1, -1)),

	normalize(float3(0, 1, PHI+1)),
	normalize(float3(0, -1, PHI+1)),
	normalize(float3(PHI+1, 0, 1)),
	normalize(float3(-PHI-1, 0, 1)),
	normalize(float3(1, PHI+1, 0)),
	normalize(float3(-1, PHI+1, 0)),

	normalize(float3(0, PHI, 1)),
	normalize(float3(0, -PHI, 1)),
	normalize(float3(1, 0, PHI)),
	normalize(float3(-1, 0, PHI)),
	normalize(float3(PHI, 1, 0)),
	normalize(float3(-PHI, 1, 0))
};
//
// Version with variable exponent.
// This is slow and does not produce correct distances, but allows for bulging of objects.
float fGDF(float3 p, float r, float e, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d += pow(abs(dot(p, GDFVectors[i])), e);
	return pow(d, 1/e) - r;
}
//
// Version with without exponent, creates objects with sharp edges and flat faces
float GDF(float3 p, float r, int begin, int end) {
	float d = 0;
	for (int i = begin; i <= end; ++i)
		d = max(d, abs(dot(p, GDFVectors[i])));
	return d - r;
}
//
//// Primitives follow:
//
float Octahedron(float3 p, float r, float e) {
	return GDF(p, r, e, 3);
}
//
float Dodecahedron2(float3 p, float r, float e) {
	return fGDF(p, r, e, 13, 18);
}
//
//float Icosahedron(float3 p, float r, float e) {
//	return fGDF(p, r, e, 3, 12);
//}
//
//float TruncatedOctahedron(float3 p, float r, float e) {
//	return fGDF(p, r, e, 0, 6);
//}
//
//float TruncatedIcosahedron(float3 p, float r, float e) {
//	return fGDF(p, r, e, 3, 18);
//}
//
//float Octahedron(float3 p, float r) {
//	return GDF(p, r, 3, 6);
//}
//
//float Dodecahedron(float3 p, float r) {
//	return GDF(p, r, 13, 18);
//}
//
//float Icosahedron(float3 p, float r) {
//	return GDF(p, r, 3, 12);
//}
//
//float TruncatedOctahedron(float3 p, float r) {
//	return GDF(p, r, 0, 6);
//}
//
//float TruncatedIcosahedron(float3 p, float r) {
//	return GDF(p, r, 3, 18);
//}

float Spiral(float3 p, float size)
{
 	return length (p.xy + float2(cos(p.z+size),sin(p.z+size)) ) - 0.1;
}

float3 pln;

float Terrain(float3 p)

		{

		float nx=floor(p.x)*10.0+floor(p.z)*100.0,center=0.0,scale=2.0;

		float4 heights=float4(0.0,0.0,0.0,0.0);


		for(int i=0;i<5;i+=1)

		{

		float2 spxz=step(float2(0.0,0.0),p.xz);

		float corner_height = lerp(lerp(heights.x, heights.y, spxz.x),

		  lerp(heights.w, heights.z, spxz.x),spxz.y);


		float4 mid_heights=(heights+heights.yzwx)*0.5;


		heights =lerp(lerp(float4(heights.x,mid_heights.x,center,mid_heights.w),

		float4(mid_heights.x,heights.y,mid_heights.y,center), spxz.x),
		lerp(float4(mid_heights.w,center,mid_heights.z,heights.w), 
		float4(center,mid_heights.y,heights.z,mid_heights.z), spxz.x), spxz.y);
		nx=nx*4.0+spxz.x+2.0*spxz.y;
		center=(center+corner_height)*0.5+cos(nx*20.0)/scale*30.0;
		p.xz=frac(p.xz)-float2(0.5,0.5);
		p*=2.0;
		scale*=2.0;
		}
		float d0=p.x+p.z;
		float2 plh=lerp( lerp(heights.xw,heights.zw,step(0.0,d0)),
		lerp(heights.xy,heights.zy,step(0.0,d0)), step(p.z,p.x));

		pln=normalize(float3(plh.x-plh.y,2.0,(plh.x-center)+(plh.y-center)));

		if(p.x+p.z>0.0)
		pln.xz=-pln.zx;

		if(p.x<p.z)
		pln.xz=pln.zx;
		p.y-=center;
		return dot(p,pln)/scale;
}
#endif
