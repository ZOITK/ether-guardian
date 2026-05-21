# Story VISION-001: ARCore/ARKit 초기화 및 카메라 권한

**Sprint**: Sprint 1 (Vision System 검증)  
**기간**: Day 1-2 (2026-05-21 ~ 2026-05-22)  
**우선순위**: 🔴 Critical (블로킹)  
**상태**: 📋 준비 완료

---

## 1. User Story (사용자 관점)

```
개발자로서
나는 실제 모바일 기기에서 카메라 피드를 실시간으로 보고 싶고,
AR 세션(ARCore/ARKit)이 초기화되어 있는지 확인하고 싶습니다.

따라서:
✅ Android 기기: 카메라 권한 요청 → 라이브 피드 표시
✅ iOS 기기: 카메라 권한 요청 → 라이브 피드 표시
✅ 권한 거부 시: 사용자 가이드 표시 → 재요청 가능
```

---

## 2. 수용 기준 (Acceptance Criteria)

### Android
```gherkin
Given: Android 기기에 앱이 설치됨
When: 앱 실행
Then: 카메라 권한 요청 대화 표시
And: 사용자가 "허용" 클릭
And: 화면에 카메라 라이브 피드 표시 (흑백 또는 컬러)
And: 콘솔 로그: "[AR Manager] ARCore 초기화 완료"
And: FPS 표시: 최소 30 FPS 이상
```

### iOS
```gherkin
Given: iOS 기기에 앱이 설치됨
When: 앱 실행
Then: 카메라 권한 요청 대화 표시
And: 사용자가 "Allow" 클릭
And: 화면에 카메라 라이브 피드 표시
And: 콘솔 로그: "[AR Manager] ARKit 초기화 완료"
And: FPS 표시: 최소 30 FPS 이상
```

### 공통
```gherkin
Given: 카메라 권한이 없는 상태
When: 권한 거부 후 앱 재실행
Then: 안내 메시지: "카메라 권한이 필요합니다"
And: [재요청] 버튼 표시
And: 버튼 클릭 시 시스템 권한 설정 화면 열림
```

---

## 3. 기술 요구사항

### Android
- **최소 API 레벨**: 26 (Android 8.0)
- **대상 API 레벨**: 33+ (Android 13+)
- **필수 권한**:
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-feature android:name="android.hardware.camera" />
  ```
- **런타임 권한 요청**: Android 6.0+(API 23+)

### iOS
- **최소 버전**: iOS 14.3 (ARKit 4 필수)
- **Info.plist 설정**:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>카메라 접근이 AR 기능에 필요합니다</string>
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>위치 정보가 영토 시스템에 필요합니다</string>
  ```

### Godot
- **버전**: 4.6
- **렌더러**: Mobile (Vulkan 권장)
- **플러그인**: Godot XR Tools (OpenXR)

---

## 4. 구현 계획

### 4.1 Phase 1: 기초 구조 (Day 1 오전)

**목표**: Android 카메라 권한 + 라이브 피드 표시

**Task**:
```
1. Android 프로젝트 설정
   └─ build.gradle: compileSdk, targetSdk 확인
   
2. AndroidManifest.xml 권한 추가
   └─ CAMERA, INTERNET 권한 정의
   
3. GDScript 권한 요청 로직
   └─ src/vision/permission_manager.gd (신규)
   └─ 런타임 권한 요청 구현
   
4. 카메라 피드 표시
   └─ src/vision/camera_display.gd (신규)
   └─ CameraServer API 활용 (camPlayer 참고)
   └─ TextureRect에 카메라 출력
```

**검증**:
```
[ ] Android 기기 연결
[ ] APK 빌드 성공
[ ] 앱 실행
[ ] 카메라 권한 대화 표시
[ ] "허용" 클릭 후 피드 표시
[ ] 콘솔: [AR Manager] 로그 출력
```

### 4.2 Phase 2: ARCore 통합 (Day 1 오후)

**목표**: ARCore 세션 생성 및 초기화

**Task**:
```
1. ARCore SDK 확인
   └─ arcore/src/main/AndroidManifest.xml
   └─ arcore 라이브러리 gradle 의존성
   
2. ARCore 초기화 로직
   └─ src/vision/ar_manager.gd 수정
   └─ _initialize_arcore() 구현
   └─ ARSession 생성 및 권한 체크
   
3. 에러 처리
   └─ ARCore 미지원 기기
   └─ 버전 호환성 문제
```

**검증**:
```
[ ] ARCore 초기화 함수 호출
[ ] 콘솔: "[AR Manager] ARCore 초기화 완료"
[ ] 앱 크래시 없음
[ ] FPS 30 이상 유지
```

### 4.3 Phase 3: iOS ARKit 통합 (Day 2)

**목표**: iOS에서 ARKit 세션 생성

**Task**:
```
1. iOS 프로젝트 설정
   └─ Info.plist: NSCameraUsageDescription 추가
   
2. ARKit 초기화 로직
   └─ src/vision/ar_manager.gd 수정
   └─ _initialize_arkit() 구현
   └─ ARSession 생성
   
3. 권한 요청 (iOS 스타일)
   └─ "앱이 카메라 접근을 요청합니다" 대화
```

**검증**:
```
[ ] iOS 기기 또는 시뮬레이터에서 테스트
[ ] 카메라 권한 요청
[ ] 콘솔: "[AR Manager] ARKit 초기화 완료"
```

---

## 5. 구현 체크리스트

### Day 1 오전 (목표: Android 카메라 권한)

```
개발 환경:
  [ ] Android Studio 열음
  [ ] /Users/zoitceo/work/godot/zoGuardian 프로젝트 로드
  [ ] Godot 4.6 연동 확인
  [ ] NDK 경로 설정 (Project Settings)

파일 생성:
  [ ] src/vision/permission_manager.gd
  [ ] src/vision/camera_display.gd
  
코드 구현:
  [ ] AndroidManifest.xml 업데이트 (CAMERA 권한)
  [ ] permission_manager.gd: 런타임 권한 요청 로직
  [ ] camera_display.gd: CameraServer 활용한 피드 표시
  [ ] ar_manager.gd: 권한 확인 후 AR 초기화
  
테스트:
  [ ] APK 빌드
  [ ] Android 기기 연결
  [ ] 앱 실행 → 권한 요청 확인
  [ ] 허용 → 카메라 피드 표시 확인
```

### Day 1 오후 (목표: ARCore 초기화)

```
코드 구현:
  [ ] src/vision/ar_manager.gd: _initialize_arcore() 상세 구현
  [ ] ARCore SDK 콜백 핸들러
  [ ] 에러 핸들링 (미지원 기기, 버전 불일치)
  
테스트:
  [ ] 콘솔 로그: "[AR Manager] ARCore 초기화 완료"
  [ ] 앱 크래시 없음
  [ ] 60초 연속 실행 → 안정성 확인
```

### Day 2 (목표: iOS ARKit)

```
파일 수정:
  [ ] Info.plist: NSCameraUsageDescription 추가
  [ ] src/vision/ar_manager.gd: _initialize_arkit() 구현
  
테스트:
  [ ] iOS 기기/시뮬레이터에서 실행
  [ ] 카메라 권한 대화 표시
  [ ] 콘솔 로그: "[AR Manager] ARKit 초기화 완료"
```

---

## 6. 파일 목록

### 신규 파일
```
src/vision/
├── permission_manager.gd ← 새로 생성
├── camera_display.gd ← 새로 생성
├── ar_manager.gd ← 수정 (스켈레톤 → 구현)
├── plane_detector.gd (수정 안함)
└── mesh_generator.gd (수정 안함)
```

### 수정할 파일
```
AndroidManifest.xml (Android 권한 추가)
Info.plist (iOS 권한 추가)
project.godot (Godot 프로젝트 설정)
```

---

## 7. 의존성

```
Godot 4.6 (이미 설치)
├─ CameraServer API
├─ OS.request_permission() (Android/iOS)
└─ Godot XR Tools (OpenXR)

ARCore SDK 1.40+
├─ android-ndk (이미 설치 가정)
└─ gradle (이미 설치 가정)

ARKit 4
└─ Xcode Command Line Tools
```

---

## 8. 실패 시나리오 & 대응

| 시나리오 | 증상 | 대응 |
|---------|------|------|
| **권한 요청 안 됨** | 카메라 피드 검은 화면 | AndroidManifest 권한 확인, Godot 권한 설정 재확인 |
| **ARCore 초기화 실패** | 콘솔 에러 | ARCore SDK 버전 확인, API 호출 순서 점검 |
| **FPS 낮음** (<30) | 버벅거림 | 렌더러 설정 확인 (Vulkan vs GLES3), 해상도 낮추기 |
| **iOS 빌드 실패** | Xcode 에러 | provisioning profile, team ID 확인 |
| **앱 크래시** | 즉시 종료 | logcat/Xcode 디버거에서 스택 트레이스 확인 |

---

## 9. 성공 정의

### 최소 기준 (MVP)
```
✅ Android 기기에서 카메라 라이브 피드 표시
✅ ARCore 세션 초기화 완료 (콘솔 로그 확인)
✅ 권한 거부 후 재요청 가능
✅ 30 FPS 이상 유지
```

### 이상적 기준
```
✅ iOS 기기에서도 동작
✅ 60 FPS 달성
✅ 메모리 <200MB
✅ 권한 설정 UI 완성
```

---

## 10. 다음 단계

**VISION-001 완료 후**:
```
→ VISION-002: 평면 감지 & 메싱 생성 (Day 3-4)
  (ar_manager.gd에서 평면 감지 콜백 구현)
```

---

## 히스토리

- **2026-05-21**: VISION-001 스토리 생성

