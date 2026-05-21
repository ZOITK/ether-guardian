# ADR-001: AR 플랫폼 선택 및 통합 전략

**상태**: Accepted  
**결정 일자**: 2026-05-21  
**수정 일자**: —  
**작성자**: ceo  

---

## 1. 문제 상황 (Context)

에테르 가디언은 **AR 기반 모바일 게임**으로 현실 공간에서 몬스터를 사냥하고 영토를 점유합니다.

**고려해야 할 요소**:
- 안드로이드 + iOS 양쪽 지원 필수
- 실시간 평면 감지 정확도 중요 (>85%)
- 모바일 배터리 제약
- 개발 복잡도 vs 성능 트레이드오프

**플랫폼별 옵션**:
1. **ARCore (Android)** + **ARKit (iOS)** ← 분리된 네이티브 SDK
2. **OpenXR (통합 표준)** ← 단일 API로 양쪽 지원
3. **커스텀 비전 처리** ← 완전 독립적 (성능 비용 높음)

---

## 2. 결정 (Decision)

### 핵심 결정

**ARCore + ARKit을 별도로 래핑하되, OpenXR 기반 Godot XR Tools로 통합하고, 성능 최적화를 위해 OpenCV C++ GDExtension 추가**

```
┌────────────────────────────────────────────┐
│ Godot 4.6 게임 로직 (GDScript)            │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│ AR Manager (추상화 레이어)                 │
│  - Android 경로 → ARCore                   │
│  - iOS 경로 → ARKit                        │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│ OpenXR Godot Plugin (Godot XR Tools)       │
│ + OpenCV GDExtension (영상 전처리)         │
└────────────────────────────────────────────┘
                    ↓
┌────────────────────────────────────────────┐
│ 네이티브 레이어                             │
│  - ARCore SDK (Android)                    │
│  - ARKit API (iOS)                         │
└────────────────────────────────────────────┘
```

### 선택 근거

| 선택지 | 정확도 | 성능 | 개발 복잡도 | 유지보수 | 최종 판정 |
|--------|--------|------|-----------|--------|----------|
| ARCore/ARKit 분리 | ⭐⭐⭐⭐⭐ (>90%) | ⭐⭐⭐⭐⭐ | 중간 | 중간 | ✅ 선택 |
| OpenXR 통합 | ⭐⭐⭐⭐ (85%) | ⭐⭐⭐ | 낮음 | 낮음 | ⚠️ 성능 손실 |
| 커스텀 비전 | ⭐⭐⭐ (75%) | ⭐⭐ | 높음 | 높음 | ❌ 비추천 |

**이유**:
1. **정확도 최우선**: 평면 감지는 게임플레이의 기반 → 플랫폼 네이티브 SDK 사용
2. **개발 시간 절약**: OpenXR 표준화로 통합 레이어 비용 감소
3. **성능 확보**: ARCore/ARKit의 전문화된 최적화 활용
4. **장기 유지보수**: 각 플랫폼의 최신 업데이트를 신속하게 반영 가능

---

## 3. 구현 전략

### 3.1 Android (ARCore)

```gdscript
# ar_manager.gd
extends Node3D

# ARCore 플러그인 인터페이스
@onready var ar_core: JNIBridge = null

func _ready():
    if OS.get_name() == "Android":
        ar_core = load("res://addons/ar_core_bridge.gd").new()
        ar_core.initialize()
        ar_core.plane_detected.connect(_on_plane_detected)

func _on_plane_detected(plane_data):
    # 평면 데이터 수신 → 메싱 생성
    var mesh = create_mesh_from_plane(plane_data)
    add_plane_to_world(mesh)
```

**요구사항**:
- Android API 26+ (ARCore 필수)
- 카메라 권한
- OpenGL ES 3.0 이상

### 3.2 iOS (ARKit)

```gdscript
# ar_kit_bridge.gd
extends Node3D

# ARKit 플러그인 인터페이스
@onready var ar_kit: ARKitInterface = null

func _ready():
    if OS.get_name() == "iOS":
        ar_kit = ARKitInterface.new()
        ar_kit.initialize()
        ar_kit.plane_added.connect(_on_plane_added)

func _on_plane_added(anchor, plane_geometry):
    # ARKit 앵커 → Godot Node 변환
    var mesh = create_mesh_from_arkit(plane_geometry)
    add_plane_to_world(mesh)
```

**요구사항**:
- iOS 14.3+ (ARKit 4)
- A12 이상 칩셋 (Neural Engine)
- LiDAR 권장 (iPhone 12 Pro+, 정확도 ±2cm)

### 3.3 OpenCV 통합 (GDExtension C++)

**목적**: 영상 전처리로 평면 감지 정확도 +5-10% 향상

```cpp
// vision_processor.h
#ifndef VISION_PROCESSOR_H
#define VISION_PROCESSOR_H

#include <godot_cpp/godot.hpp>
#include <opencv2/opencv.hpp>

class VisionProcessor : public godot::Node {
    GDCLASS(VisionProcessor, godot::Node)

public:
    // 영상 전처리: 노이즈 제거, 명도 정규화
    void preprocess_frame(godot::PackedByteArray raw_frame);
    
    // 엣지 감지 (선택사항, 평면 경계 강화)
    void detect_edges(godot::PackedByteArray processed_frame);
    
    // 성능 로깅
    void log_pipeline_stats();

private:
    cv::Mat current_frame;
    double frame_process_time_ms;
};

#endif
```

**OpenCV 의존성**:
```cmake
# GDExtension CMakeLists.txt
find_package(OpenCV 4.5 REQUIRED)
target_link_libraries(vision_processor ${OpenCV_LIBS})

# 필요 모듈:
# - opencv_imgproc (노이즈 제거, 필터)
# - opencv_core (행렬 연산)
```

---

## 4. 결과 (Consequences)

### 긍정적 영향

✅ **높은 정확도**: ARCore 평면 감지 >90%, ARKit >95%  
✅ **최적화된 성능**: 각 플랫폼의 하드웨어 가속 활용 (NEON, Metal)  
✅ **빠른 피드백**: 플랫폼 업데이트 신속 반영  
✅ **LiDAR 지원**: iPhone 12 Pro+ 에서 깊이 정보 활용 가능  

### 부정적 영향 / 제약사항

⚠️ **플랫폼별 코드 분기**: Android/iOS 각각 테스트 필요  
⚠️ **배터리 소비**: ARCore/ARKit 사용 시 5-7%/10분 (높음)  
⚠️ **메모리 오버헤드**: Android ~150-200MB, iOS ~100-150MB  
⚠️ **저사양 기기 지원 한계**: Snapdragon 4 이하에서 성능 저하  

### 완화 전략

- **다중 스레드**: 영상 처리를 워커 스레드에서 실행
- **적응형 해상도**: 기기 성능에 따라 해상도 자동 조정
- **배터리 최적화**: 게임 일시 중지 시 AR 중단
- **우아한 성능 저하**: FPS 목표를 동적으로 조정

---

## 5. 대안 검토 (Alternatives Considered)

### 5.1 OpenXR 통합 (단일 API)

**장점**:
- 코드 분기 최소화 (단일 인터페이스)
- 다른 XR 플랫폼 확장 용이 (VR, MR)

**단점**:
- ARCore/ARKit의 최신 기능 지연 (OpenXR 표준 update lag)
- 평면 감지 정확도 감소 (5-10%)
- Godot XR Tools 성숙도 아직 낮음

**결정**: ❌ 거부 (정확도와 성능 우선)

### 5.2 커스텀 비전 처리 (OpenCV만 사용)

**장점**:
- 완전 제어 가능
- 플랫폼 의존성 제거

**단점**:
- 매우 높은 개발 비용 (4-6주)
- 평면 감지 정확도 <75% (상업 수준 미달)
- 배터리 소비 증가 (카메라 처리 > ARCore/ARKit)
- 유지보수 부담 증가

**결정**: ❌ 거부 (초기 프로토타입에 부적합)

---

## 6. 구현 계획

### Phase 1: ARCore 통합 (1주)
- [ ] Android SDK 설정
- [ ] ARCore 초기화 및 권한 관리
- [ ] 기본 평면 감지 (바닥)
- [ ] 벤치마크: 60FPS 달성 확인

### Phase 2: ARKit 통합 (1주)
- [ ] iOS 프로젝트 설정
- [ ] ARKit 앵커 시스템 연동
- [ ] 성능 비교 (ARCore vs ARKit)

### Phase 3: OpenCV 통합 (1주)
- [ ] GDExtension 빌드 환경 설정
- [ ] 영상 전처리 (노이즈 제거, CLAHE)
- [ ] 정확도 향상 측정

### Phase 4: 통합 테스트 (1주)
- [ ] 실제 기기 테스트 (다양한 환경)
- [ ] 배터리 소비 측정
- [ ] 성능 프로파일링

---

## 7. 성공 기준

- ✅ Android 평면 감지 정확도 >85%
- ✅ iOS 평면 감지 정확도 >90%
- ✅ 60FPS 유지 (고성능 기기)
- ✅ 45FPS 이상 (중간 기기)
- ✅ 메모리 <500MB
- ✅ 배터리 세션 30분 이상

---

## 8. 참고자료

- [ARCore 공식 문서](https://developers.google.com/ar/develop)
- [ARKit 공식 문서](https://developer.apple.com/arkit/)
- [OpenXR 사양](https://www.khronos.org/openxr/)
- [Godot XR Tools](https://github.com/GodotVR/godot_xr_tools)
- [OpenCV 4.5](https://docs.opencv.org/)

