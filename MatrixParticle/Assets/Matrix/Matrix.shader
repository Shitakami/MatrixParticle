Shader "Unlit/Matrix"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Texture", 2D) = "white" {}
		_TilingAndOffset("Tiling And Offset", Vector) = (1, 1, 0, 0)
		_RowCount ("Row Count", int) = 1

		_MaxIndexX ("Max Index X", int) = 0
        _MaxIndexY ("Max Index Y", int) = 0
        _Index ("Index", int) = 0

        _TimeSpeed ("Time Speed", float) = 1
        _Period ("Period", float) = 1
        _PeriodSeed ("Period Seed", float) = 0
        _EraseSpeed ("Erase Speed", float) = 1

        _BaseLetterColor ("Base Letter Color", Color) = (1, 1, 1, 1)
        _WhiteColorThreshold ("White Color Threshold", float) = 1
        _DiscardThreshold ("Discard Threashold", Range(0, 1)) = 0.5
        _Sharpness ("Sharpness", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Blend SrcAlpha OneMinusSrcAlpha 
        LOD 100
        
        Pass
        {
            ZWrite ON
            ColorMask 0
        }
        Pass
        {
            ZWrite OFF
            Ztest LEqual
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #define PI 3.141592

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _TilingAndOffset;
			uniform float _RowCount;
            uniform float _MaxIndexX;
            uniform uint _MaxIndexY;
            uniform uint _Index;
            uniform fixed _DiscardThreshold;
            uniform half _TimeSpeed;
            uniform half _Period;
            uniform half _PeriodSeed;
            uniform half _EraseSpeed;
            uniform fixed4 _BaseLetterColor;
            uniform fixed _WhiteColorThreshold;
            uniform float _Sharpness;
            
            float GetRandomNumber(float2 texCoord, int Seed)
            {
                return frac(sin(dot(texCoord.xy, float2(12.9898, 78.233)) + Seed) * 43758.5453);
            }

            float2 RotateUV(float2 uv, float theta, uint xReverseFlag, uint yReverseFlag)
            {
                 half2x2 mat = half2x2(cos(theta), -sin(theta), sin(theta), cos(theta));

                uv = uv - 0.5;
                uv = mul(uv, mat) + 0.5;
                
                uv.x = uv.x * (1 - xReverseFlag) + (1 - uv.x) * xReverseFlag;
                uv.y = uv.y * (1 - yReverseFlag) + (1 - uv.y) * yReverseFlag;

                return uv;
            }

            fixed4 MatrixTex(float2 uv)
            {
                float2 gridUV = frac(uv * _RowCount);
                uint maxIndex = _MaxIndexX * _MaxIndexY;
                
                float r = floor(uv.x * _RowCount) + _Index;
                float c = floor(uv.y * _RowCount) - _Index;
                float rnd = GetRandomNumber(float2(r, c), 0);
                float timeOffset = GetRandomNumber(float2(r, -c), 0);
                uint index = rnd * 10000 + _Time.w + timeOffset;
                index = (index + _Index) % maxIndex;
                uint indexX = index % _MaxIndexX;
                uint indexY = index / _MaxIndexX;
                float letterSizeX = _TilingAndOffset.x;
                float letterSizeY = _TilingAndOffset.y;
                gridUV.x *= _TilingAndOffset.x;
                gridUV.y *= _TilingAndOffset.y;
                gridUV.x += _TilingAndOffset.z + letterSizeX * indexX;
                gridUV.y += _TilingAndOffset.w - letterSizeY * indexY;

                half theta = -PI + step(index, 30) * PI + step(index, 60) * PI + step(index, 90) * PI;

                fixed xReverseFlag = step(0.5, rnd);
                fixed yReverseFlag = step(index, 60);
                gridUV = RotateUV(gridUV, theta, xReverseFlag, yReverseFlag);

                fixed4 col = tex2D(_MainTex, gridUV);
                 
                half column = floor(uv.x * _RowCount);
                half periodOffset = GetRandomNumber(float2(column + _PeriodSeed, -column), _PeriodSeed) * 100;
                fixed alphaRate = saturate(1 - frac(uv.y * _Period + _Time.y * _TimeSpeed + periodOffset) * _EraseSpeed);
                fixed rate = saturate((alphaRate - _WhiteColorThreshold)/(1 - _WhiteColorThreshold));
                if(col.b > _DiscardThreshold)
                    alphaRate = 0;
                
                return lerp(fixed4(_BaseLetterColor.xyz, alphaRate), float4(1, 1, 1, alphaRate), rate);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.worldPos = worldPos.xyz;
                o.normal = abs(UnityObjectToWorldNormal(v.normal));
                o.normal = pow(o.normal, _Sharpness);
                o.normal = o.normal / (o.normal.x + o.normal.y + o.normal.z);
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv_front = i.worldPos.xy;
                float2 uv_side = i.worldPos.zy;
                float2 uv_top = i.worldPos.xz;
                fixed4 col_front = MatrixTex(uv_front) * i.normal.z;
                fixed4 col_side = MatrixTex(uv_side) * i.normal.x;
                fixed4 col_top = MatrixTex(uv_top) * i.normal.y;
                return col_front + col_side + col_top;
            }
            ENDCG
        }
    }
}
