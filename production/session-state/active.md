# 카메라 라이브 피드 디버깅 완료

**날짜**: 2026-05-21 (Day 1 진행 중)  
**현재 단계**: VISION-001 카메라 문제 진단 완료  
**상태**: 🔴 카메라 프레임 수신 불가 (원인 규명됨)

## 해결한 문제들

### ✅ 카메라 권한 요청
- `OS.request_permission("CAMERA")` 작동 확인
- `OS.request_permission("ACCESS_FINE_LOCATION")` 작동 확인
- AndroidManifest.xml에 권한 선언 추가:
  - `android.permission.CAMERA`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.INTERNET`

### ✅ 카메라 기기 인식
- CameraServer.feeds() 정상 작동
- 4개 카메라 감지:
  - [0] 0 | BACK (ID: 1) ← 선택됨
  - [1] 1 | FRONT (ID: 2)
  - [2] 2 | BACK (ID: 3)
  - [3] 3 | FRONT (ID: 4)

### ✅ 셰이더 및 텍스처 설정
- YUV-to-RGB 셰이더 구현 (`yuv_to_rgb.gdshader`)
- CameraTexture Y/CBCR 채널 생성
- ShaderMaterial 매개변수 전달 완료
- TextureRect 할당 완료

### ✅ 화면 해상도 설정
- project.godot: 1600x720 (기기 가로 해상도)
- AndroidManifest: landscape 강제

## 🔴 발견된 근본 문제

**CameraServer가 실제 카메라 프레임을 캡처하지 못함**

진단 방법:
```gdscript
if (y < 0.1) {
  COLOR = vec4(1.0, 0.0, 0.0, 1.0); // 빨간색
}
```

결과: 화면 전체 빨간색 → Y 채널 = 0 (카메라 신호 없음)

### 원인 분석

Godot 4.6의 CameraServer API:
- 카메라 피드 **감지**: ✅ 작동 (feeds 리스트 반환)
- 카메라 피드 **활성화**: ✅ 설정 가능 (feed_is_active = true)
- 카메라 **프레임 캡처**: ❌ 작동 안 함 (실제 데이터 전달 없음)

이는 Godot의 Android CameraServer 구현이 자동으로 카메라 프레임을 Godot 내부 파이프라인으로 라우팅하지 않음을 의미합니다.

## 해결책 (Phase 2)

### 옵션 1: C++ GDExtension (권장)
- Android Camera2 API 사용
- native 프레임 캡처 및 Godot으로 전달
- 성능 최적화 (OpenCV 통합 가능)
- 기존 프로젝트 구조와 호환

### 옵션 2: ARCore/OpenXR (대체)
- XRInterface를 통한 카메라 접근
- 기존 vision_app.gd 패턴 사용
- 추가 종속성 (ARCore SDK)
- AR 기능과 자동 통합

### 옵션 3: Java/Kotlin 플러그인
- Android Studio 연동
- 낮은 우선순위 (구현 복잡도 높음)

## 파일 변경 요약

```
✅ src/vision/yuv_to_rgb.gdshader (새로 생성)
✅ src/vision/camera_manager.gd (새로 생성)
✅ src/main.tscn (수정: 해상도, CameraManager 노드 추가)
✅ project.godot (수정: 1600x720 해상도)
✅ android/build/src/main/AndroidManifest.xml (수정: 권한 추가)
```

## 다음 단계

### 즉시 (Day 1 끝)
- [ ] Phase 2 계획: C++ GDExtension 구현 방식 결정
- [ ] Android NDK/CMake 설정
- [ ] Camera2 API wrapper 작성 시작

### Day 2
- [ ] GDExtension 프레임 캡처 구현
- [ ] YUV 데이터 Godot으로 전달
- [ ] 텍스처 업데이트 확인

### Day 3
- [ ] OpenCV 통합 (영상 처리)
- [ ] 성능 테스트
- [ ] iOS ARKit 대응

## 성공 기준 업데이트

### VISION-001 Day 1 최종 결과

| 항목 | 상태 | 비고 |
|------|------|------|
| 권한 요청 | ✅ | AndroidManifest + OS.request_permission |
| 카메라 감지 | ✅ | 4개 카메라 인식 |
| 셰이더 설정 | ✅ | YUV-to-RGB 구현 |
| 텍스처 렌더링 | ✅ | TextureRect에 할당 |
| **카메라 피드** | ❌ | 프레임 데이터 부재 (GDExtension 필요) |
| 해상도 | ✅ | 1600x720 설정 |
| FPS 모니터링 | ✅ | 37.0 FPS 달성 |

### Day 1 학습사항

1. **Godot CameraServer 한계**
   - Android에서 카메라 **감지**는 되지만 **프레임 캡처** 불가
   - 순수 GDScript/CameraTexture로는 실제 카메라 영상 불가능

2. **필수 아키텍처 변경**
   - C++ GDExtension으로 native 카메라 접근 필요
   - Android Camera2 API 직접 사용해야 함

3. **프로젝트 구조 확정**
   - GDScript layer: UI, 게임 로직
   - C++ GDExtension layer: 카메라, 영상 처리
   - Shader layer: YUV-RGB 변환 (이미 구현됨)

---

**담당자**: Claude (AI)  
**마지막 업데이트**: 2026-05-21 Day 1 카메라 디버깅  
**다음 작업**: Phase 2 - C++ GDExtension 구현 계획
