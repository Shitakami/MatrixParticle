Shader "Unlit/TextMapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _MaxIndexX ("Max Index X", int) = 0
        _MaxIndexY ("Max Index Y", int) = 0
        
        _DiscardThreshold ("Discard Threashold", Range(0, 1)) = 0.5
    }
    
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha 
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float4 color : TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float index : TEXCOORD1;
                float seed : TEXCOORD2;
                float4 color : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _DiscardThreshold;

            int _Index;

            uniform int _MaxIndexX;
            uniform int _MaxIndexY;
            
            float GetRandomNumber(float2 texCoord, int Seed)
            {
                return frac(sin(dot(texCoord.xy, float2(12.9898, 78.233)) + Seed) * 43758.5453);
            }
            
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.index = v.uv.z;
                o.seed = v.uv.w;
                o.color = v.color;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float letterSizeX = _MainTex_ST.x;
                float letterSizeY = _MainTex_ST.y;
                
                uint maxIndex = _MaxIndexX * _MaxIndexY;
                
                uint time = floor(_Time.w * frac(i.seed));
                uint index = GetRandomNumber(float2(time, time + i.seed), i.seed) * 10000;
                index = index % maxIndex;
                
                uint indexX = index % _MaxIndexX;
                uint indexY = index / _MaxIndexX;

                i.uv.x += letterSizeX * indexX;
                i.uv.y -= letterSizeY * indexY;
                
                fixed4 col = tex2D(_MainTex, i.uv);
                if(col.b > _DiscardThreshold)
                    discard;
                
                UNITY_APPLY_FOG(i.fogCoord, col);
                return i.color;
            }
            ENDCG
        }
    }
}
