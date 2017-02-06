Shader "FFT/FFTShader"{
	Properties{
	_MainTex ("Texture", 2D) = "white" {}
	_Displacement ("Displacement", Range(0, 20.0)) = 0.3
	}
	SubShader{

		Pass{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
				//float2 texcoord : TEXCOORD0;
			};

			struct v2f{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 screenCoord : TEXCOORD1;
				float3 normal : NORMAL;
			};
			sampler2D _MainTex;
			float _Displacement;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.uv;
				//float d = tex2Dlod(_MainTex, float4(v.uv.xy,0,0)).r*_Displacement;
				//v.vertex.xyz += v.normal * _Displacement;
				o.screenCoord.xy = ComputeScreenPos(o.vertex);
				return o;
			}

			#define PI 3.14159
			#define EPSILON 0.001
			#define Thick 0.03
			#define Width 2.0
			#define Amp 0.09
			#define Velocity 1.0
			
			fixed4 frag (v2f i) : SV_Target

			{
				float2 c = i.uv;
				float4 s = tex2D(_MainTex, c * 0.5);
				c = float2 (0.0, Amp*s.y*sin((c.x*Width+_Time.y*Velocity)*2.5)) + (c*2.0-1.0);	
				float g = max(abs(s.y/(pow(c.y,2.1*sin(s.x*PI))))*Thick, abs(0.1/(c.y+EPSILON)));
				return float4(g*g*s.y*0.6,g*s.w*0.44,g*g*0.7,1.0);
			}
			ENDCG
		}
	}
}
