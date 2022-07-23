Shader "Unlit/keqing shader"
{
    Properties
    {
        [Header(Shader Enum)]
        [Space(5)]
        //[KeywordEnum(BASE,FACE,HAIR)] _SHADERENUM("shader分支选择", int) = 0
        [Toggle(_SHADERENUM_BASE)] _SHADERENUM_BASE("身体",int) = 0
        [Toggle(_SHADERENUM_FACE)] _SHADERENUM_FACE("脸",int) = 0
        [Toggle(_SHADERENUM_HAIR)] _SHADERENUM_HAIR("头发",int) = 0
        [Toggle(IN_NIGHT)]_InNight("是否为晚上", int) = 0

        [Header(Texture)]
        [Space(5)]
        _MainTex ("Texture", 2D) = "white" {}
        //衣服（ r：glossiness控制高光范围，g :specular控制高光形状 ，b:lightmap阴影部分，a:ramp texture)
        // 头发（ r：metal金属，g :specular控制高光形状 ，b:lightmap阴影部分，a:glossiness控制高光范围，)
        _ParamTex("参数图", 2D) = "grey"{}
        _RampTex("映射图", 2D) = "white"{}
        _Matcap("matcap", 2D) = "white"{}
        _FaceShadowTex("脸部阴影贴图", 2D) = "grey"{}
        /*
        [Header(Param)]
        [Space(5)]
        _RampMapYRange("RampTexture采样颜色", Range(0.0, 0.5)) = 0.3
        _SpecularPow("高光次幂", Range(10.0, 200.0)) = 50.0
        _SpecularInt("高光强度", Range(0.0, 5.0)) = 2.0
        _RimPow("边缘光幂", Range(0.0, 30.0)) = 1.0
        _RinInt("边缘光强度", Range(0.0, 0.5)) = 1.0
        _EmissionInt("自发光强度", Range(1.0, 5.0)) = 2.0
        _EmissionSpeed("发光频率", Range(1.0, 4.0)) = 2.0
        _FaceShadowRangeSmooth("面部阴影模糊程度", Range(0.1, 1.0)) = 0.1

        [Header(OutlineParam)]
        [Space(5)]
        _OutlineWidth("轮廓线宽度", Range(0.0001, 0.0003)) = 0.0001
        _OutlineCol("轮廓线颜色", color) = (1.0,1.0,1.0)
        */
    }
        SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            Name "FORWARD"
            Tags {
                "LightMode" = "ForwardBase"
            }
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #pragma multi_compile_fwdbase_fullshadows

            //分支声明
            #pragma shader_feature __  _SHADERENUM_BASE _SHADERENUM_FACE _SHADERENUM_HAIR

            uniform int _InNight;

            uniform  sampler2D _MainTex;
            uniform  sampler2D _ParamTex;
            uniform sampler2D _RampTex;
            uniform sampler2D _Matcap;
            uniform sampler2D _FaceShadowTex;
            
            uniform float _SpecularPow;
            uniform float _SpecularInt;
            uniform float _RimPow;
            uniform float _RinInt;
            uniform float _EmissionInt;
            uniform float _EmissionSpeed;
            uniform float _RampMapYRange;
            uniform float _FaceShadowRangeSmooth;

            uniform float3 _G_testCol;


            //输入结构
            struct VertexInput
            {
                float4 vertex   : POSITION;
                float2 uv       : TEXCOORD0;
                float4 color    : COLOR;
                float4 normal   : NORMAL;
            };
            
            //输出结构
            struct VertexOutput
            {   
                float4 vertex   : SV_POSITION;
                float2 uv       : TEXCOORD0;
                float4 color    : COLOR;
                float3 nDirWS   : TEXCOORD1;
                float3 nDirVS   : TEXCOORD2;
                float3 vDirWS   : TEXCOORD3;
                float3 posWS    : TEXCOORD4;
            };

            //顶点shader
            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.nDirVS = mul(UNITY_MATRIX_V, float4(o.nDirWS, 0.0));
                o.vDirWS = _WorldSpaceCameraPos.xyz - o.posWS;
                return o;
            }

            //ramptexture 采样函数
            float3 NPR_Ramp(float NdotL, float _RampMapYRange ) {

                float halfLambertRamp = smoothstep(0.0, 0.5, NdotL * 0.5 + 0.5);

                if(_InNight > 0.0){
                    float3 var_rampTex = tex2D(_RampTex, float2(halfLambertRamp, _RampMapYRange));
                    return var_rampTex;
                }
                else {
                    float3 var_rampTex = tex2D(_RampTex, float2(halfLambertRamp, _RampMapYRange + 0.5));
                    return var_rampTex;
                }

            }

            //specular
            float NPR_Specular(float HdotN, float4 var_ParamTex, float3 baseCol) {

                //不同分支用不同的高光贴图
#if defined(_SHADERENUM_HAIR)
                float specularPow = pow(HdotN, var_ParamTex.a * _SpecularPow);
#else
                float specularPow = pow(HdotN, var_ParamTex.r * _SpecularPow);
#endif

                float3 specularCol = var_ParamTex.b * baseCol;  //主颜色乘阴影

#if defined(_SHADERENUM_HAIR)
                float specular = smoothstep(0.3, 0.4, specularPow) * lerp(_SpecularInt, 1.0, var_ParamTex.b) * specularCol ;
                return specular;
#else
                float specular = smoothstep(0.3, 0.4, specularPow) * var_ParamTex.b * specularCol;
                return specular;
#endif
            }

            //metal
            float3 NPR_Metal(float3 nDirVS, float4 var_ParamTex, float3 baseCol) {
                float2 mapUV = nDirVS.rg * 0.5 + 0.5;
                float3 var_matcap = tex2D(_Matcap, mapUV);

#if defined(_SHADERENUM_HAIR)
                float3 metalCol = var_matcap * baseCol * var_ParamTex.a;
                return metalCol;
#else
                float3 metalCol = var_matcap * baseCol * var_ParamTex.r;
                return metalCol;
#endif
            }

            //边缘光,用菲尼尔
            float3 NPR_Rim(float3 VdotN, float3 NdotL, float3 baseCol) {
                float3 light = 1 - (NdotL * 0.5 + 0.5);
                float3 rim = (1.0 - smoothstep(_RimPow, _RimPow + 0.03, VdotN) * _RinInt * light) * baseCol ;
                return rim;
            }

            //自发光
            float3 NPR_emissionCol(float emissionTex, float3 baseCol) {
                float3 emission = emissionTex * _EmissionInt * baseCol * abs((frac(_Time.y * 0.5) - 0.5) * _EmissionSpeed);
                return emission;
            }

            //脸部
            float3 NRF_FaceShadow(float ndotl, float3 baseCol, float var_FaceShadowTex, float3 lDir, float _RampMapYRange) {
                float3 Up = float3(0.0, 1.0, 0.0);
                float3 Front = unity_ObjectToWorld._12_22_32;
                float3 Right = cross(Up, Front);
                float2 rightXZ = normalize(Right.xz);
                float2 lDirXZ = normalize(lDir.xz);
                float switchShadow = dot(rightXZ, lDirXZ) * 0.5 + 0.5 < 0.5;
                float FaceShadow = lerp(var_FaceShadowTex, 1- var_FaceShadowTex, switchShadow) ;
                float frontXZ = normalize(Front.xz);
                float FaceShadowRange = dot(frontXZ, lDirXZ);
                float lightAttenuation = 1 - smoothstep(FaceShadowRange - _FaceShadowRangeSmooth, FaceShadowRange + _FaceShadowRangeSmooth, FaceShadow);
                float3 rampCol = NPR_Ramp(lightAttenuation *(ndotl * 5), _RampMapYRange)+0.35;
                float3 faceCol = rampCol * baseCol + ndotl * 0.1;
                
                return faceCol;
            }

            //头部
            float3 NRF_Hair(float NdotL, float _RampMapYRange, float3 baseCol, float HdotN, float4 var_ParamTex, float3 nDirVS, float3 VdotN) {
                float3 rampCol = NPR_Ramp(NdotL * 0.5 + 0.5, _RampMapYRange);
                float3 DiffuseCol = rampCol * baseCol ;
                 
                float hairSpecPow = 0.25;
                float3 hairSpecDir = normalize(nDirVS) * 0.5 + 0.5;
                float3 hairSpec = smoothstep(hairSpecPow, hairSpecPow + 0.1, 1 - hairSpecDir) * smoothstep(hairSpecPow, hairSpecPow+0.1, hairSpecDir) * NdotL;
                float3 specularCol = NPR_Specular(HdotN, var_ParamTex, baseCol);
                float3 metalCol = NPR_Metal(nDirVS, var_ParamTex, baseCol);
                float3 rimCol = NPR_Rim(VdotN, NdotL, baseCol);
                float3 finalCol = DiffuseCol  + specularCol * 0.2 * rampCol + metalCol * 0.4 + rimCol * 0.6;
                return finalCol ;

            }

            //身体
            float3 NRF_Base(float NdotL, float _RampMapYRange, float3 baseCol, float HdotN, float4 var_ParamTex, float3 nDirVS, float3 VdotN, float emissionTex) {
                float3 rampCol = NPR_Ramp(NdotL * 0.5 + 0.5, _RampMapYRange);
                float3 DiffuseCol = rampCol * baseCol;
                float3 specularCol = NPR_Specular(HdotN, var_ParamTex, baseCol);
                float3 metalCol = NPR_Metal(nDirVS, var_ParamTex, baseCol);
                float3 rimCol = NPR_Rim(VdotN, NdotL, baseCol) * var_ParamTex.g;
                float3 emissionCol = NPR_emissionCol(emissionTex, baseCol);
                float3 finalCol = DiffuseCol * (1 - var_ParamTex.r) + specularCol + metalCol + rimCol + emissionCol;
                return finalCol;
            }


            //像素shader
            float4 frag (VertexOutput i) : COLOR
            {
                // 采样图像
                float3 baseCol = tex2D(_MainTex, i.uv).rgb;
                float emissionTex = tex2D(_MainTex, i.uv).a;
                float4 var_ParamTex = tex2D(_ParamTex, i.uv);
                float var_FaceShadowTex = tex2D(_FaceShadowTex, i.uv).r;

               

                //向量准备
                float3 nDirWS = normalize(i.nDirWS);
                float3 nDirVS = normalize(i.nDirVS);
                float3 vDirWS = normalize(i.vDirWS);
                float3 vrDirWS = normalize(reflect(-vDirWS, nDirWS));
                float3 lDirWS = _WorldSpaceLightPos0.xyz;
                float3 lrDirWS = reflect(lDirWS, nDirWS);
                float3 hDirWS = normalize(lDirWS + vDirWS);


                //中间量准备
                float ndotl = dot(nDirWS, lDirWS);  //漫反射模型
                float ndoth = dot(nDirWS, hDirWS);  //高光反射模型
                float ndotv = dot(nDirWS, vDirWS); //菲涅尔

                float3 finalCol = (0.0,0.0,0.0);

#if defined(_SHADERENUM_BASE)
                finalCol = NRF_Base(ndotl, _RampMapYRange, baseCol, ndoth, var_ParamTex, nDirVS, ndotv, emissionTex);
#elif defined(_SHADERENUM_FACE)
                finalCol = NRF_FaceShadow(ndotl,baseCol, var_FaceShadowTex, lDirWS, _RampMapYRange);
#elif defined(_SHADERENUM_HAIR)
                finalCol = NRF_Hair(ndotl, _RampMapYRange, baseCol, ndoth, var_ParamTex, nDirVS, ndotv);
#endif
                
                return float4(finalCol,1.0);
            }
            ENDCG
        }

        Pass
        {
            Name "Outline"
            Tags {
               "RenderType" = "Opaque" 
               "Queue" = "Geometry"
            }
            Cull Off
            ZWrite on
            Cull front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            uniform  sampler2D _MainTex;
            uniform float _OutlineWidth;
            uniform float3 _OutlineCol;

            struct VertexInput
            {
                float4 vertex    : POSITION;
                float3 normal    : NORMAL;
                float2 uv0       :TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 pos      : SV_POSITION;
                float3 posWS    : TEXCOORD0;
                float2 uv0      : TEXCOORD1;
                float3 nDirWS   : TEXCOORD2;
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                o.pos = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal * _OutlineWidth, 1.0));
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.uv0 = float2(v.uv0.x, 1-v.uv0.y);
                o.nDirWS = v.normal;
                return o;
            }

            float4 frag(VertexOutput i) : SV_Target
            {
                float3 baseCol = tex2D(_MainTex, i.uv0).rgb;
                float3 FinalCol = baseCol * _OutlineCol;
                return float4(FinalCol, 1);
            }
            ENDCG
         }

            Pass
            {
                Tags{
                    "LightMode" = "ShadowCaster"
                }
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_shadowcaster

                #include "UnityCG.cginc"

                struct appdata {
                    float4 vertex : POSITION;
                    float4 uv : TEXCOORD0;
                };

                struct v2f {
                    V2F_SHADOW_CASTER;
                };

                v2f vert(appdata v) {
                    v2f o;
                    TRANSFER_SHADOW_CASTER(o);
                    return o;
                }
                fixed4 frag(v2f i) : SV_Target {
                    SHADOW_CASTER_FRAGMENT(i)
                }
                ENDCG
            }
           
    }
            
}
