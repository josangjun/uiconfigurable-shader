# UI Configurable Shader

Unity UI와 2D 스프라이트에서 공통으로 사용할 수 있는 투명 셰이더입니다. 기본 텍스처에 색상·밝기·마스크·그레이스케일·Fill 효과를 조합할 수 있으며, Unity UI의 클리핑과 스텐실 설정도 지원합니다.

패키지 정보:

- Package: `com.xsystem.uiconfigurable-shader`
- Version: `0.1.0`
- Unity: `6000.0` 이상
- Render pipeline: Universal Render Pipeline `17.6.0`
- Shader: `UI/Configurable Shader`

## 설치

이 저장소의 루트에는 Unity Package Manager가 인식하는 `package.json`이 있습니다.

### 로컬 패키지로 설치

1. Unity에서 `Window > Package Manager`를 엽니다.
2. `+ > Add package from disk...`를 선택합니다.
3. 이 저장소의 `package.json`을 선택합니다.

프로젝트의 `Packages/manifest.json`에 로컬 경로를 직접 등록하는 방법도 사용할 수 있습니다.

```json
{
  "dependencies": {
    "com.xsystem.uiconfigurable-shader": "file:../uiconfigurable-shader"
  }
}
```

URP 프로젝트가 아니라면 셰이더가 사용하는 `Core.hlsl` 및 2D 관련 include를 찾지 못할 수 있습니다. 이 패키지는 URP `17.6.0`을 기준으로 작성되었습니다.

## 기본 사용법

1. Project 창에서 `Create > Material`을 생성합니다.
2. Material의 Shader를 `UI/Configurable Shader`로 지정합니다.
3. `Main Tex`에 기본 텍스처를 넣습니다.
4. 생성한 Material을 `Image`, `RawImage` 또는 호환되는 2D 렌더러에 연결합니다.

`Color`는 텍스처 색상뿐 아니라 정점 색상과 `SpriteRenderer` 색상에도 곱해집니다. 따라서 UI Graphic의 색상이나 SpriteRenderer의 색상 변경도 최종 색상에 반영됩니다.

## Material 프로퍼티

### 기본 색상과 텍스처

| 프로퍼티 | 설명 |
| --- | --- |
| `Main Tex` (`_MainTex`) | 기본 RGB 및 알파 텍스처입니다. |
| `Color` (`_Color`) | 기본 텍스처에 곱하는 색상입니다. |
| `Intensity` (`_Intensity`) | RGB 밝기 배율입니다. 범위는 `0`~`10`입니다. 알파에는 적용되지 않습니다. |

### 마스크

| 프로퍼티 | 설명 |
| --- | --- |
| `Mask` (`_Mask`) | 마스크로 사용할 텍스처입니다. |
| `MaskChannel` (`_MaskChannel`) | 마스크로 읽을 채널입니다. `Red`, `Green`, `Blue`, `Alpha` 중 하나를 선택합니다. |

마스크 처리는 `MASK` 로컬 셰이더 키워드가 켜진 경우에만 실행됩니다. `_Mask`에 텍스처를 지정하는 것만으로는 마스크가 활성화되지 않을 수 있으므로, Material의 키워드 또는 프로젝트의 Material 설정에서 `MASK`를 활성화해야 합니다.

```csharp
var material = new Material(Shader.Find("UI/Configurable Shader"));
material.SetTexture("_MainTex", mainTexture);
material.SetTexture("_Mask", maskTexture);
material.SetFloat("_MaskChannel", 3); // Alpha
material.EnableKeyword("MASK");
```

마스크를 켜면 선택한 채널 값이 기본 텍스처의 알파에 곱해집니다. 마스크 텍스처의 RGB를 사용하려면 해당 채널에 값을 넣어야 합니다. 프로퍼티 라벨은 `Mask Alpha (A)`로 표시되지만, 실제 셰이더는 선택한 채널을 읽습니다.

### Tint와 Fill

| 프로퍼티 | 설명 |
| --- | --- |
| `Tint Method` (`_Tint`) | `None` 또는 `Fill`을 선택합니다. |
| `FillColor` (`_FillColor`) | Fill에 사용할 색상입니다. |
| `FillPhase` (`_FillPhase`) | 원본 색상에서 Fill 색상으로 보간하는 정도입니다. `0`은 원본, `1`은 Fill 쪽입니다. |

`Tint Method`를 `Fill`로 설정하면 셰이더 키워드 `_TINT_FILL`이 사용됩니다. Fill 색상은 `FillColor.rgb * 현재 알파`로 계산되어 원본 RGB와 보간됩니다.

### Grayscale과 알파 클리핑

| 프로퍼티 | 설명 |
| --- | --- |
| `Grayscale` (`_Grayscale`) | 그레이스케일 처리를 켭니다. |
| `Saturate` (`_Saturate`) | 그레이스케일과 원본 색상 사이의 보간값입니다. `0`은 완전한 그레이스케일, `1`은 원본 색상입니다. |
| `Use Alpha Clip` (`_UseUIAlphaClip`) | 알파 클리핑을 켭니다. |
| `Cutout` (`_Cutout`) | 알파 클리핑 기준값입니다. 기본값은 `0.3`입니다. |

그레이스케일 밝기는 `0.3R + 0.59G + 0.11B`로 계산됩니다. 알파 클리핑을 켜면 기준값보다 작은 알파가 `clip`되어 픽셀이 버려집니다.

## UI 및 렌더링 설정

다음 프로퍼티는 UI Material 또는 Sprite 렌더링 파이프라인과 맞춰야 하는 고급 설정입니다.

- `Stencil Id`, `StencilReadMask`, `StencilWriteMask`
- `StencilComp`, `StencilOp`, `Stencil Fail`, `Stencil ZFail`
- `Color Mask`
- `Culling`, `ZTest`, `ZWrite`
- `Blending Op`, `Blending Source`, `Blending Dest`

Canvas의 `RectMask2D` 등에서 `UNITY_UI_CLIP_RECT` 키워드가 설정되면 `_ClipRect`를 사용해 클리핑합니다. 클리핑이 적용되려면 사용 중인 UI 렌더러가 해당 키워드와 클립 값을 전달해야 합니다.

## 셰이더 키워드

| 키워드 | 기능 |
| --- | --- |
| `MASK` | `_Mask` 텍스처를 샘플링하고 선택한 채널을 알파에 곱합니다. |
| `_TINT_NONE` / `_TINT_FILL` | Tint 모드를 선택합니다. |
| `GRAYSCALE` | 그레이스케일 보간을 켭니다. |
| `UNITY_UI_ALPHACLIP` | `Cutout` 기준으로 알파 클리핑을 켭니다. |
| `UNITY_UI_CLIP_RECT` | `_ClipRect` 기반 UI 사각형 클리핑을 켭니다. |
| `SKINNED_SPRITE` | Unity 2D Sprite Skinning 경로를 사용합니다. |

`MASK`, `GRAYSCALE`, `UNITY_UI_ALPHACLIP`은 셰이더의 로컬 키워드입니다. Material마다 필요한 기능만 활성화하면 불필요한 변형을 줄일 수 있습니다.

## 구현 구조

`Runtime/Shaders/UIConfigurable.shader`에는 두 개의 SubShader가 있습니다.

- `LOD 200`: URP HLSL 경로입니다. URP Core 및 2D include를 사용하고, 마스크·그레이스케일·Fill·UI 클리핑·알파 클리핑·Sprite Skinning을 지원합니다.
- `LOD 100`: 고급 HLSL 경로를 사용할 수 없는 환경을 위한 레거시 fallback입니다. 기본 텍스처와 색상 곱셈, 기본 알파 블렌딩 중심으로 동작하며 고급 기능은 보장되지 않습니다.

Material Inspector는 `Studio.Framework.TransparentFxGUI`를 사용하도록 지정되어 있습니다. 해당 에디터 타입은 이 패키지에 포함되어 있지 않으므로, 이를 제공하는 프로젝트 프레임워크가 없는 환경에서는 기본 Material Inspector를 사용하거나 해당 타입을 프로젝트에 추가해야 합니다.

## 주의사항

- 이 패키지는 런타임 스크립트나 Material 에셋을 포함하지 않습니다. 필요한 Material은 사용하는 프로젝트에서 생성하고 관리해야 합니다.
- 셰이더 이름은 `UI/Configurable Shader`입니다. 코드에서 `Shader.Find`를 사용할 때 이 이름을 그대로 사용해야 합니다.
- 마스크·그레이스케일·알파 클립은 각 키워드가 활성화되어야 동작합니다.
- 이 저장소에는 전용 테스트 씬이나 자동화된 셰이더 테스트가 포함되어 있지 않습니다. 실제 프로젝트의 Canvas, SpriteRenderer, 플랫폼별 그래픽 API에서 확인해야 합니다.

## 라이선스

MIT License. 자세한 내용은 [LICENSE](LICENSE)를 확인하세요.
