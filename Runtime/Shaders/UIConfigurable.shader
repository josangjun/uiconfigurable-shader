Shader "UI/Configurable Shader"
{
	Properties
	{
		_MainTex ("Base (RGB), Alpha (A)", 2D) = "white" {}
		_Mask ("Mask Alpha (A)", 2D) = "black" {}
		_Color ("Color", Color) = (1,1,1,1)
		_Intensity ("Intensity", Range(0,10)) = 1
		_Cutout ("Cutout", Range(0, 1)) = 0.3
		[Enum(Red,0,Green,1,Blue,2,Alpha,3)] _MaskChannel ("MaskChannel", Int) = 1
		[IntRange] _Stencil ("Stencil Id", Range(0, 255)) = 0
		[IntRange] _StencilReadMask ("StencilReadMask", Range(0, 255)) = 255
		[IntRange] _StencilWriteMask ("StencilWriteMask", Range(0, 255)) = 255
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("StencilComp", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("StencilOp", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail ("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail ("Stencil ZFail", Int) = 0
		[Enum(Nothing,0,Alpha,1,Blue,2,Green,4,Red,8,All,15)] _ColorMask("Color Mask", Int) = 15
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Culling", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 4
		[Enum(Off,0,On,1)] _ZWrite("ZWrite", Int) = 0
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blending Op", Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Blending Source", Int) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Blending Dest", Int) = 10
		[KeywordEnum(None, Fill)] _Tint ("Tint Method", Int) = 0
		_FillColor ("FillColor", Color) = (1,1,1,1)
		_FillPhase ("FillPhase", Range(0, 1)) = 0
		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Int) = 0
		[Toggle(GRAYSCALE)] _Grayscale ("Grayscale", Int) = 0
		_Saturate ("Saturate", Range(0,1)) = 0
	}
	
	SubShader
	{
		LOD 200

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Lighting Off
			ColorMask [_ColorMask]
			Stencil {
				Ref [_Stencil]
				ReadMask [_StencilReadMask]
				WriteMask [_StencilWriteMask]
				Comp [_StencilComp]
				Pass [_StencilOp]
				Fail [_StencilFail]
				ZFail [_StencilZFail]
			}
			Cull [_CullMode]
			ZTest [_ZTest]
			ZWrite [_ZWrite]
			BlendOp [_BlendOp]
			Blend [_SrcBlend] [_DstBlend]
			Lighting Off
			Fog { Mode Off }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_local _ GRAYSCALE
			#pragma multi_compile_local _ UNITY_UI_ALPHACLIP
			#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
			#pragma shader_feature_local _TINT_NONE _TINT_FILL
			#pragma shader_feature_local MASK
			#pragma enable_cbuffer
			// Match URP's 2D Sprite shaders so SpriteSkin can provide its global keyword.
			#pragma multi_compile_instancing
			#pragma multi_compile _ SKINNED_SPRITE
			
			// These includes provide UNITY_SKINNED_VERTEX_INPUTS/COMPUTE and the
			// _SpriteBoneTransforms path used by Unity's 2D Sprite Skinning.
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/Core2D.hlsl"
			
			CBUFFER_START(UnityPerMaterial)
			sampler2D _MainTex;
			half4 _MainTex_ST;
			sampler2D _Mask;
			half4 _Mask_ST;
			half4 _Color;
			half4 _FillColor;
			half _FillPhase;
			half _Intensity;
			half _Saturate;
			half _Cutout;
			half _MaskChannel;
			CBUFFER_END
			
			float4 _ClipRect;
			
			struct appdata_t
			{
				float3 positionOS : POSITION;
				half2 texcoord : TEXCOORD0;
				half4 color : COLOR;
				UNITY_SKINNED_VERTEX_INPUTS
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
	
			struct v2f
			{
				float4 vertex : SV_POSITION;
				half2 texcoord : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				#if MASK
				half2 texcoord1 : TEXCOORD2;
				#endif
				half4 color : COLOR;
			};
	
			float4 UnityObjectToClipPos(float4 pos)
			{
				return mul(UNITY_MATRIX_MVP, pos);
			}
			
			v2f vert (appdata_t v)
			{
				v2f o;

				UNITY_SETUP_INSTANCE_ID(v);
			#if defined(SKINNED_SPRITE)
				UNITY_SKINNED_VERTEX_COMPUTE(v);
				SetUpSpriteInstanceProperties();
				v.positionOS = UnityFlipSprite(v.positionOS, unity_SpriteProps.xy);
			#endif
				o.worldPosition = float4(v.positionOS, 1.0);
				o.vertex = TransformObjectToHClip(v.positionOS);
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				#if MASK
				o.texcoord1 = TRANSFORM_TEX(v.texcoord, _Mask);
				#endif
				o.color = v.color * _Color * unity_SpriteColor;
				o.color.rgb *= _Intensity;

				return o;
			}
			
			half4 frag (v2f IN) : COLOR
			{
				half4 col = tex2D(_MainTex, IN.texcoord) * IN.color;
				#if GRAYSCALE
				col.rgb = lerp(dot(col.rgb, half3(0.3, 0.59, 0.11)), col.rgb, _Saturate);
				#endif

				#if MASK
				half4 mask = tex2D(_Mask, IN.texcoord1);
				col.a *= mask[_MaskChannel];
				#endif
				
				#if _TINT_FILL
				col.rgb = lerp(col.rgb, _FillColor.rgb * col.a, _FillPhase);
				//col.rgb = lerp(col.rgb, _FillColor.rgb, _FillPhase);
				#endif
				
				#if UNITY_UI_CLIP_RECT
				col.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				#endif
				#if UNITY_UI_ALPHACLIP
				clip(col.a - _Cutout);
				#endif
				return col;
			}
			ENDHLSL
		}
	}
	
	SubShader
	{
		LOD 100

		Tags
		{
			"Queue" = "Transparent"
			"IgnoreProjector" = "True"
			"RenderType" = "Transparent"
		}
		
		Pass
		{
			Cull Off
			Lighting Off
			ZWrite Off
			Fog { Mode Off }
			Offset -1, -1
			ColorMask RGB
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMaterial AmbientAndDiffuse
			
			SetTexture [_MainTex]
			{
				Combine Texture * Primary
			}
		}
	}
	CustomEditor "Studio.Framework.TransparentFxGUI"
}
