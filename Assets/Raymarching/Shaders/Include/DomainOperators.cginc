#ifndef DOMAINOPERATORS_H
#define DOMAINOPERATORS_H

// pfunctions's are domain modifiers
#define myMod(x,y) (x-y*floor(x/y))


// Most of these are ported from Mercury's sdf database, converted from GLSL to HLSL, not all have been tested...


float sgn(float x) {
	return (x<0)?-1:1;
}

float2 sgn(float2 v) {
	return float2((v.x<0)?-1:1, (v.y<0)?-1:1);
}

inline void pR(inout float2 p, float a) {
	p = cos(a)*p + sin(a)*float2(p.y, -p.x);
}

// Shortcut for 45-degrees rotation
void pR45(inout float2 p) {
	p = (p + float2(p.y, -p.x))*sqrt(0.5);
}

// Repeat space along one axis. Use like this to repeat along the x axis:
// <float cell = pmyMod1(p.x,5);> - using the return value is optional.
inline float pMod1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = myMod(p + halfsize, size) - halfsize;
	return c;
}

// Same, but mirror every second cell so they match at the boundaries
inline float pModMirror1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = myMod(p + halfsize,size) - halfsize;
	p *= myMod(c, 2.0)*2 - 1;
	return c;
}

// Repeat the domain only in positive direction. Everything in the negative half-space is unchanged.
inline float pModSingle1(inout float p, float size) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	if (p >= 0)
		p = myMod(p + halfsize, size) - halfsize;
	return c;
}

// Repeat only a few times: from indices <start> to <stop> (similar to above, but more flexible)
inline float pModInterval1(inout float p, float size, float start, float stop) {
	float halfsize = size*0.5;
	float c = floor((p + halfsize)/size);
	p = myMod(p+halfsize, size) - halfsize;
	if (c > stop) { //yes, this might not be the best thing numerically.
		p += size*(c - stop);
		c = stop;
	}
	if (c <start) {
		p += size*(c - start);
		c = start;
	}
	return c;
}


// Repeat around the origin by a fixed angle.
// For easier use, num of repetitions is use to specify the angle.
inline float pModPolar(inout float2 p, float repetitions) {
	float angle = 2*PI/repetitions;
	float a = atan2(p.x, p.y) + angle/2.;
	float r = length(p);
	float c = floor(a/angle);
	a = myMod(a,angle) - angle/2.;
	p = float2(cos(a), sin(a))*r;
	// For an odd number of repetitions, fix cell index of the cell in -x direction
	// (cell index would be e.g. -5 and 5 in the two halves of the cell):
	if (abs(c) >= (repetitions/2)) c = abs(c);
	return c;
}

// Repeat in two dimensions
inline float2 pMod2(inout float2 p, float2 size) {
	float2 c = floor((p + size*0.5)/size);
	p = myMod(p + size*0.5,size) - size*0.5;
	return c;
}

// Same, but mirror every second cell so all boundaries match
inline float2 pModMirror2(inout float2 p, float2 size) {
	float2 halfsize = size*0.5;
	float2 c = floor((p + halfsize)/size);
	p = myMod(p + halfsize, size) - halfsize;
	p *= myMod(c,float2(2,2))*2 - float2(1,1);
	return c;
}

// Same, but mirror every second cell at the diagonal as well
inline float2 pModGrid2(inout float2 p, float2 size) {
	float2 c = floor((p + size*0.5)/size);
	p = myMod(p + size*0.5, size) - size*0.5;
	p *= myMod(c,float2(2,2))*2 - float2(1,2);
	p -= size/2;
	if (p.x > p.y) p.xy = p.yx;
	return floor(c/2);
}

// Repeat in three dimensions
inline float3 pMod3(inout float3 p, float3 size) {
	float3 c = floor((p + size*0.5)/size);
	p = myMod(p + size*0.5, size) - size*0.5;
	return c;
}

// Mirror at an axis-aligned plane which is at a specified distance <dist> from the origin.
inline float pMirror (inout float p, float dist) {
	float s = (p);
	p = abs(p)-dist;
	return s;
}

// Mirror in both dimensions and at the diagonal, yielding one eighth of the space.
// translate by dist before mirroring.
inline float2 pMirrorOctant (inout float2 p, float2 dist) {
	float2 s = sgn(p);
	pMirror(p.x, dist.x);
	pMirror(p.y, dist.y);
	if (p.y > p.x)
		p.xy = p.yx;
	return s;
}

// Reflect space at a plane
inline float pReflect(inout float3 p, float3 planeNormal, float offst) {
	float t = dot(p, planeNormal)+offst;
	if (t < 0) {
		p = p - (2*t)*planeNormal;
	}
	return sgn(t);
}

inline float UnionChamferOp(float a, float b, float r) {
	return min(min(a, b), (a - r + b)*sqrt(0.5));
}

//The alpha blending for shapes ... amt is amount of blend, a) and b) are input shapes
inline float AlphaBlendOp(float a, float b, float amt)
{
	return amt * a + (1.0 - amt) * b;
}

inline float3 DisplaceOp(float3 pos, float3 a)
{
	float3 d = a+pos;
	return d;
}

// Intersection has to deal with what is normally the inside of the resulting object
// when using union, which we normally don't care about too much. Thus, intersection
// implementations sometimes differ from union implementations.
inline float IntersectionChamferOp(float a, float b, float r) {
	return max(max(a, b), (a + r + b)*sqrt(0.5));
}

// Difference can be built from Intersection or Union:
inline float DifferenceChamferOp (float a, float b, float r) {
	return IntersectionChamferOp(a, -b, r);
}

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
inline float UnionRoundOp(float a, float b, float r) {
	float2 u = max(float2(r - a,r - b), float2(0,0));
	return max(r, min (a, b)) - length(u);
}

inline float IntersectionRoundOp(float a, float b, float r) {
	float2 u = max(float2(r + a,r + b), float2(0,0));
	return min(-r, max (a, b)) + length(u);
}

inline float DifferenceRoundOp (float a, float b, float r) {
	return IntersectionRoundOp(a, -b, r);
}


// The "Columns" flavour makes n-1 circular columns at a 45 degree angle:
inline float UnionColumnsOp(float a, float b, float r, float n) {
	if ((a < r) && (b < r)) {
		float2 p = float2(a, b);
		float columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));
		pR45(p);
		p.x -= sqrt(2)/2*r;
		p.x += columnradius*sqrt(2);
		if (myMod(n,2) == 1) {
			p.y += columnradius;
		}
		// At this point, we have turned 45 degrees and moved at a point on the
		// diagonal that we want to place the columns on.
		// Now, repeat the domain along this direction and place a circle.
		pMod1(p.y, columnradius*2);
		float result = length(p) - columnradius;
		result = min(result, p.x);
		result = min(result, a);
		return min(result, b);
	} else {
		return min(a, b);
	}
}

inline float DifferenceColumnsOp(float a, float b, float r, float n) {
	a = -a;
	float m = min(a, b);
	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r)) {
		float2 p = float2(a, b);
		float columnradius = r*sqrt(2)/n/2.0;
		columnradius = r*sqrt(2)/((n-1)*2+sqrt(2));

		pR45(p);
		p.y += columnradius;
		p.x -= sqrt(2)/2*r;
		p.x += -columnradius*sqrt(2)/2;

		if (myMod(n,2) == 1) {
			p.y += columnradius;
		}
		pMod1(p.y,columnradius*2);

		float result = -length(p) + columnradius;
		result = max(result, p.x);
		result = min(result, a);
		return -min(result, b);
	} else {
		return -m;
	}
}

inline float IntersectionColumnsOp(float a, float b, float r, float n) {
	return DifferenceColumnsOp(a,-b,r, n);
}

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
inline float UnionStairsOp(float a, float b, float r, float n) {
	float s = r/n;
	float u = b-r;
	return min(min(a,b), 0.5 * (u + a + abs ((myMod (u - a + s, 2 * s)) - s)));
}

// We can just call Union since stairs are symmetric.
inline float IntersectionStairsOp(float a, float b, float r, float n) {
	return -UnionStairsOp(-a, -b, r, n);
}

inline float DifferenceStairsOp(float a, float b, float r, float n) {
	return -UnionStairsOp(-a, b, r, n);
}


// Similar to fOpUnionRound, but more lipschitz-y at acute angles
// (and less so at 90 degrees). Useful when fudging around too much
// by MediaMolecule, from Alex Evans' siggraph slides
inline float UnionSoftOp(float a, float b, float r) {
	float e = max(r - abs(a - b), 0);
	return min(a, b) - e*e*0.25/r;
}


// produces a cylindical pipe that runs along the intersection.
// No objects remain, only the pipe. This is not a boolean operator.
inline float PipeOp(float a, float b, float r) {
	return length(float2(a, b)) - r;
}

// first object gets a v-shaped engraving where it intersect the second
inline float EngraveOp(float a, float b, float r) {
	return max(a, (a + r - abs(b))*sqrt(0.5));
}

// first object gets a capenter-style groove cut out
inline float GrooveOp(float a, float b, float ra, float rb) {
	return max(a, min(a + ra, rb - abs(b)));
}

// first object gets a capenter-style tongue attached
inline float TongueOp(float a, float b, float ra, float rb) {
	return min(a, max(a - ra, abs(b) - rb));
}

#endif
