#ifndef NOISE_H
#define NOISE_H

#define myMod(x,y) (x-y*floor(x/y))
sampler2D _MainTex;

inline float PerlinNoise(float3 p) // I think this is just in 2D and bad, jaggies all over the place
{
	float3 i = floor(p);
	float4 a = dot(i,float3(1.0,57.0,21.0))+float4(0.0,57.0,21.0,78.0);
	float3 f = cos((p-i)*3.1416)*(-0.5)+0.5;
	a = lerp(sin(cos(a)*a),sin(cos(1.0+a)*(1.0+a)),f.x);
	a.xy = lerp(a.xy,a.yw,f.y);
	return lerp(a.x,a.y,f.z);
}


float3 mod7(float3 x) {
  return x - floor(x * (1.0 / 7.0)) * 7.0;
}

float3 mod289(float3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}



float4 mod289(float4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float3 permute(float3 x) {
  return mod289((34.0 * x + 1.0) * x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

inline float SimplexNoise(float3 v)
  { 
  const float2  C = float2(1.0/6.0, 1.0/3.0) ;
  const float4  D = float4(0.0, 0.5, 1.0, 2.0);

// First corner
  float3 i  = floor(v + dot(v, C.yyy) );
  float3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  float3 g = step(x0.yzx, x0.xyz);
  float3 l = 1.0 - g;
  float3 i1 = min( g.xyz, l.zxy );
  float3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  float3 x1 = x0 - i1 + C.xxx;
  float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289(i); 
  float4 p = permute( permute( permute( 
             i.z + float4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + float4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  float3  ns = n_ * D.wyz - D.xzx;

  float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  float4 x_ = floor(j * ns.z);
  float4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  float4 x = x_ *ns.x + ns.yyyy;
  float4 y = y_ *ns.x + ns.yyyy;
  float4 h = 1.0 - abs(x) - abs(y);

  float4 b0 = float4( x.xy, y.xy );
  float4 b1 = float4( x.zw, y.zw );

  //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
  //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
  float4 s0 = floor(b0)*2.0 + 1.0;
  float4 s1 = floor(b1)*2.0 + 1.0;
  float4 sh = -step(h, float4(0.0,0.0,0.0,0.0));

  float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
  float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  float3 p0 = float3(a0.xy,h.x);
  float3 p1 = float3(a0.zw,h.y);
  float3 p2 = float3(a1.xy,h.z);
  float3 p3 = float3(a1.zw,h.w);

//Normalise gradients
  float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }

//  	float noise( in float2 x, tex2D _MainTex )
//			{
//			    float2 p = floor(x);
//			    float2 f = frac(x);
//			    f = f*f*(3.0-2.0*f);
//			    float e = tex2D(_MainTex,(p+float2(0.5,0.5))/256.0).x;
//				float b = tex2D(_MainTex,(p+float2(1.5,0.5))/256.0).x;
//				float c = tex2D(_MainTex,(p+float2(0.5,1.5))/256.0).x;
//				float d = tex2D(_MainTex,(p+float2(1.5,1.5))/256.0).x;
//			    return lerp(lerp( e, b,f.x), lerp( c, d,f.x),f.y);
//			}
//
//
//			//const mat2 mtx = mat2( 0.80,  0.60, -0.60,0.80);
//			const float2 mtx1 = float2( 0.80,  0.60);
//			const float2 mtx2 = float2( -0.60,  0.80 );
//
//			float fbm4( float2 p, tex2D tex )
//			{
//			    float f = 0.0;
//
//			    f += 0.5000*(-1.0+2.0*noise( p, tex )); p = mtx2*p*3.02;
//			    f += 0.2500*(-1.0+2.0*noise( p, tex )); p = mtx2*p*3.03;
//			    f += 0.1250*(-1.0+2.0*noise( p, tex )); p = mtx2*p*3.01;
//			    f += 0.0625*(-1.0+2.0*noise( p, tex ));
//
//			    return f/0.9375;
//			}
//
//			float fbm6( float2 p, tex2D tex )
//			{
//			    float f = 0.0;
//
//			    f += 0.500000*noise( p, tex); p = mtx2*p*2.02;
//			    f += 0.250000*noise( p, tex); p = mtx2*p*2.03;
//			    f += 0.125000*noise( p, tex); p = mtx2*p*2.01;
//			    f += 0.062500*noise( p, tex); p = mtx2*p*2.04;
//			    f += 0.031250*noise( p, tex); p = mtx2*p*2.01;
//			    f += 0.015625*noise( p, tex);
//
//			    return f/0.96875;
//			}
//
//			float func( float2 q, out float2 o, out float2 n, tex2D tex )
//			{
//			    float ql = length( q );
//			    q.x += 0.5*sin(0.01*_Time.y+ql*1.1);
//			    q.y += 0.5*sin(0.093*_Time.y+ql*1.2);
//			    q *= 0.7 + 0.2*cos(0.1*_Time.y);
//
//			    q = (q+0.1)*0.5;
//
//			    o.x = 0.5 + 0.5*fbm4( float2(6.0*q*float2(1.0,1.0)          ), tex  );
//			    o.y = 0.5 + 0.5*fbm4( float2(6.0*q*float2(1.0,1.0)+float2(5.2,5.2)), tex  );
//
//			    float ol = length( o );
//			    o.x += 0.2*sin(1.11*_Time.y*ol)/ol;
//			    o.y += 0.2*sin(1.13*_Time.y*ol)/ol;
//
//
//			    n.x = fbm6( float2(4.0*o*float2(1.0,1.0)+float2(1.2,1.2)),tex  );
//			    n.y = fbm6( float2(4.0*o*float2(1.0,1.0)+float2(1.7,1.7)),tex  );
//
//			    float2 p = (4)*q + (4)*n;
//
//			    float f = 0.5 + 0.5*fbm4( p,tex );
//
//			    f = lerp( f, f*f*f*3.5, f*abs(n.x) );
//
//			    float g = 0.5+0.5*sin(2.0*p.x)*sin(2.0*p.y);
//			    f *= 1.0-0.5*pow( g, 8.0 );
//
//			    return f;
//			}
//
//			float funcs( in float2 q )
//			{
//			    float2 t1, t2;
//			    return func(q,t1,t2);
//			}
//
//inline float FractalNoise (float2 p, tex2D tex)
//{
//	//float2 p = i.uv;
//	float2 q = (2.0 -16.0*p);
//	//float q = i.uv * 16;
//	
//    float2 o, n;
//    float f = func(q, o, n, tex);
//    return f;
//}

float3 shape( in float2 p )
{
	p *= 2.0;
	
	float3 s = float3( 0.0 , 0.0, 0.0);
	float2 z = p;
	for( int i=0; i<8; i++ ) 
	{
        // transform		
		z += cos(z.yx + cos(z.yx + cos(z.yx+0.5*_Time.y) ) );

        // orbit traps		
		float d = dot( z-p, z-p ); 
		s.x += 1.0/(1.0+d);
		s.y += d;
		s.z += sin(atan2(z.y-p.y,z.x-p.x));
		
	}
	
	return s / 8.0;
}

float3 GooShape (float2 p)
{
    p = p*2-1/min(1,1);

	float2 pa = p + float2(0.04,0.0);
	float2 pb = p + float2(0.0,0.04);
	
    // shape (3 times for diferentials)	
	float3 sc = shape( p );
	float3 sa = shape( pa );
	float3 sb = shape( pb );

    // color	
	float3 col = lerp( float3(0.08,0.02,0.15), float3(0.6,1.1,1.6), sc.x );
	col = lerp( col, col.zxy, smoothstep(-0.5,0.5,cos(0.5*_Time.y)) );
	col *= 0.15*sc.y;
	col += 0.4*abs(sc.z) - 0.1;

	return col;
}


inline float2 CellularNoise3D(float3 P) 
{
	#define K 0.142857142857 // 1/7
	#define Ko 0.428571428571 // 1/2-K/2
	#define K2 0.020408163265306 // 1/(7*7)
	#define Kz 0.166666666667 // 1/6
	#define Kzo 0.416666666667 // 1/2-1/6*2
	#define jitter 1.0 // smaller jitter gives more regular pattern

	float3 Pi = mod289(floor(P));
 	float3 Pf = frac(P) - 0.5;

	float3 Pfx = Pf.x + float3(1.0, 0.0, -1.0);
	float3 Pfy = Pf.y + float3(1.0, 0.0, -1.0);
	float3 Pfz = Pf.z + float3(1.0, 0.0, -1.0);

	float3 p = permute(Pi.x + float3(-1.0, 0.0, 1.0));
	float3 p1 = permute(p + Pi.y - 1.0);
	float3 p2 = permute(p + Pi.y);
	float3 p3 = permute(p + Pi.y + 1.0);

	float3 p11 = permute(p1 + Pi.z - 1.0);
	float3 p12 = permute(p1 + Pi.z);
	float3 p13 = permute(p1 + Pi.z + 1.0);

	float3 p21 = permute(p2 + Pi.z - 1.0);
	float3 p22 = permute(p2 + Pi.z);
	float3 p23 = permute(p2 + Pi.z + 1.0);

	float3 p31 = permute(p3 + Pi.z - 1.0);
	float3 p32 = permute(p3 + Pi.z);
	float3 p33 = permute(p3 + Pi.z + 1.0);

	float3 ox11 = frac(p11*K) - Ko;
	float3 oy11 = mod7(floor(p11*K))*K - Ko;
	float3 oz11 = floor(p11*K2)*Kz - Kzo; // p11 < 289 guaranteed

	float3 ox12 = frac(p12*K) - Ko;
	float3 oy12 = mod7(floor(p12*K))*K - Ko;
	float3 oz12 = floor(p12*K2)*Kz - Kzo;

	float3 ox13 = frac(p13*K) - Ko;
	float3 oy13 = mod7(floor(p13*K))*K - Ko;
	float3 oz13 = floor(p13*K2)*Kz - Kzo;

	float3 ox21 = frac(p21*K) - Ko;
	float3 oy21 = mod7(floor(p21*K))*K - Ko;
	float3 oz21 = floor(p21*K2)*Kz - Kzo;

	float3 ox22 = frac(p22*K) - Ko;
	float3 oy22 = mod7(floor(p22*K))*K - Ko;
	float3 oz22 = floor(p22*K2)*Kz - Kzo;

	float3 ox23 = frac(p23*K) - Ko;
	float3 oy23 = mod7(floor(p23*K))*K - Ko;
	float3 oz23 = floor(p23*K2)*Kz - Kzo;

	float3 ox31 = frac(p31*K) - Ko;
	float3 oy31 = mod7(floor(p31*K))*K - Ko;
	float3 oz31 = floor(p31*K2)*Kz - Kzo;

	float3 ox32 = frac(p32*K) - Ko;
	float3 oy32 = mod7(floor(p32*K))*K - Ko;
	float3 oz32 = floor(p32*K2)*Kz - Kzo;

	float3 ox33 = frac(p33*K) - Ko;
	float3 oy33 = mod7(floor(p33*K))*K - Ko;
	float3 oz33 = floor(p33*K2)*Kz - Kzo;

	float3 dx11 = Pfx + jitter*ox11;
	float3 dy11 = Pfy.x + jitter*oy11;
	float3 dz11 = Pfz.x + jitter*oz11;

	float3 dx12 = Pfx + jitter*ox12;
	float3 dy12 = Pfy.x + jitter*oy12;
	float3 dz12 = Pfz.y + jitter*oz12;

	float3 dx13 = Pfx + jitter*ox13;
	float3 dy13 = Pfy.x + jitter*oy13;
	float3 dz13 = Pfz.z + jitter*oz13;

	float3 dx21 = Pfx + jitter*ox21;
	float3 dy21 = Pfy.y + jitter*oy21;
	float3 dz21 = Pfz.x + jitter*oz21;

	float3 dx22 = Pfx + jitter*ox22;
	float3 dy22 = Pfy.y + jitter*oy22;
	float3 dz22 = Pfz.y + jitter*oz22;

	float3 dx23 = Pfx + jitter*ox23;
	float3 dy23 = Pfy.y + jitter*oy23;
	float3 dz23 = Pfz.z + jitter*oz23;

	float3 dx31 = Pfx + jitter*ox31;
	float3 dy31 = Pfy.z + jitter*oy31;
	float3 dz31 = Pfz.x + jitter*oz31;

	float3 dx32 = Pfx + jitter*ox32;
	float3 dy32 = Pfy.z + jitter*oy32;
	float3 dz32 = Pfz.y + jitter*oz32;

	float3 dx33 = Pfx + jitter*ox33;
	float3 dy33 = Pfy.z + jitter*oy33;
	float3 dz33 = Pfz.z + jitter*oz33;

	float3 d11 = dx11 * dx11 + dy11 * dy11 + dz11 * dz11;
	float3 d12 = dx12 * dx12 + dy12 * dy12 + dz12 * dz12;
	float3 d13 = dx13 * dx13 + dy13 * dy13 + dz13 * dz13;
	float3 d21 = dx21 * dx21 + dy21 * dy21 + dz21 * dz21;
	float3 d22 = dx22 * dx22 + dy22 * dy22 + dz22 * dz22;
	float3 d23 = dx23 * dx23 + dy23 * dy23 + dz23 * dz23;
	float3 d31 = dx31 * dx31 + dy31 * dy31 + dz31 * dz31;
	float3 d32 = dx32 * dx32 + dy32 * dy32 + dz32 * dz32;
	float3 d33 = dx33 * dx33 + dy33 * dy33 + dz33 * dz33;

	// Sort out the two smallest distances (F1, F2)
#if 0
	// Cheat and sort out only F1
	float3 d1 = min(min(d11,d12), d13);
	float3 d2 = min(min(d21,d22), d23);
	float3 d3 = min(min(d31,d32), d33);
	float3 d = min(min(d1,d2), d3);
	d.x = min(min(d.x,d.y),d.z);
	return float2(sqrt(d.x)); // F1 duplicated, no F2 computed
#else
	// Do it right and sort out both F1 and F2
	float3 d1a = min(d11, d12);
	d12 = max(d11, d12);
	d11 = min(d1a, d13); // Smallest now not in d12 or d13
	d13 = max(d1a, d13);
	d12 = min(d12, d13); // 2nd smallest now not in d13
	float3 d2a = min(d21, d22);
	d22 = max(d21, d22);
	d21 = min(d2a, d23); // Smallest now not in d22 or d23
	d23 = max(d2a, d23);
	d22 = min(d22, d23); // 2nd smallest now not in d23
	float3 d3a = min(d31, d32);
	d32 = max(d31, d32);
	d31 = min(d3a, d33); // Smallest now not in d32 or d33
	d33 = max(d3a, d33);
	d32 = min(d32, d33); // 2nd smallest now not in d33
	float3 da = min(d11, d21);
	d21 = max(d11, d21);
	d11 = min(da, d31); // Smallest now in d11
	d31 = max(da, d31); // 2nd smallest now not in d31
	d11.xy = (d11.x < d11.y) ? d11.xy : d11.yx;
	d11.xz = (d11.x < d11.z) ? d11.xz : d11.zx; // d11.x now smallest
	d12 = min(d12, d21); // 2nd smallest now not in d21
	d12 = min(d12, d22); // nor in d22
	d12 = min(d12, d31); // nor in d31
	d12 = min(d12, d32); // nor in d32
	d11.yz = min(d11.yz,d12.xy); // nor in d12.yz
	d11.y = min(d11.y,d12.z); // Only two more to go
	d11.y = min(d11.y,d11.z); // Done! (Phew!)
	return sqrt(d11.xy); // F1, F2
	#endif
}

const float2 m = float2( 0.80,  0.60 );

float hasher( float2 p )
{
	float h = dot(p,float2(127.1,311.7));
    return -1.0 + 2.0*frac(sin(h)*43758.5453123);
}

float noise2( in float2 p )
{
    float2 i = floor( p );
    float2 f = frac( p );
	
	float2 u = f*f*(3.0-2.0*f);

    return lerp( lerp( hasher( i + float2(0.0,0.0) ), 
                     hasher( i + float2(1.0,0.0) ), u.x),
                lerp( hasher( i + float2(0.0,1.0) ), 
                     hasher( i + float2(1.0,1.0) ), u.x), u.y);
}

float fbmotion( float2 p )
{
    float f = 0.0;
    f += 0.5000*noise2( p ); p = m*p*2.02;
    f += 0.2500*noise2( p ); p = m*p*2.03;
    f += 0.1250*noise2( p ); p = m*p*2.01;
    f += 0.0625*noise2( p );
    return f/0.9375;
}

float2 fbmotion2( in float2 p )
{
    return float2( fbmotion(p.xy), fbmotion(p.yx) );
}

float3 func2( float2 p )
{   
    p *= 2.9;

    float f = dot( fbmotion2( 1.0*(0.5*_Time.y + p + fbmotion2(-0.5*_Time.y+1.0*(p + fbmotion2(4.0*p)))) ), float2(1.0,-1.0) );

    float bl = smoothstep( -0.8, 0.8, f );

    float ti = smoothstep( -1.0, 1.0, fbmotion(p) );

    return lerp( lerp( float3(0.50,0.00,0.00), 
                     float3(1.00,0.5,0.35), ti ), 
                     float3(0.00,0.00,0.02), bl );
}

float3 FBMotion (float2 p)
{
    float e = 0.0016;
    float3 colc = func2( p               ); float gc = dot(colc,float3(0.333, 0.333, 0.333));
    float3 cola = func2( p + float2(e,0.0) ); float ga = dot(cola,float3(0.333, 0.333, 0.333));
    float3 colb = func2( p + float2(0.0,e) ); float gb = dot(colb,float3(0.333, 0.333, 0.333));

    float3 nor = normalize( float3(ga-gc, e, gb-gc ) );

    float3 col = colc;

    col += float3(0.1,0.1,8.3)*1.0*abs(3.0*gc-ga-gb);
    col *= 0.5+0.2*nor.y*nor.y;
    col += 0.05*nor.y*nor.y*nor.y;

    return col;
}

#endif
