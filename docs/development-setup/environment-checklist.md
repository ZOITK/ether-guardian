# 개발 환경 체크리스트

**작성일**: 2026-05-21  
**목표**: Sprint 1 Day 1 개발 시작 전 환경 검증

---

## 1. Godot 엔진 설정

### Godot 4.6 설치 확인

```bash
# 확인 방법:
$ /Applications/Godot.app/Contents/MacOS/Godot --version

# 예상 출력:
# Godot Engine v4.6.x.official

# 필수 설정:
✅ Editor → Project Settings → XR
   ├─ OpenXR 플러그인 활성화
   ├─ Godot XR Tools 다운로드
   └─ Android/iOS export template 설치
```

### Godot 프로젝트 설정

```gdscript
# project.godot 확인:
[application]
config/name="Ether Guardian"
config/version="0.1.0"

[rendering]
renderer/rendering_method="mobile"
textures/vram_compression/import_etc2_astc=true

[xr]
openxr/enabled=true
openxr/default_action_map="res://xr_default_action_map.tres"
```

---

## 2. Android 환경 설정

### Android SDK/NDK 설치 확인

```bash
# 확인:
$ echo $ANDROID_SDK_ROOT
$ echo $ANDROID_NDK_ROOT

# 예상 출력:
# /usr/local/share/android-sdk
# /usr/local/share/android-ndk

# 미설치 시 설치:
brew install android-sdk android-ndk openjdk@17
```

### Android Studio 설정

```
1. Android Studio 열기
2. Tools → SDK Manager
   └─ SDK Platforms: Android 13 (API 33) 설치
   └─ SDK Tools:
      ├─ Android SDK Build-Tools 33.x
      ├─ NDK (Side by side) 26.x
      └─ Android SDK Platform-Tools
3. SDK Location 확인: ~/Library/Android/sdk
```

### Godot Android Export 설정

```
Editor → Project → Project Settings → Export
└─ Android
   ├─ SDK Path: /usr/local/share/android-sdk
   ├─ NDK Path: /usr/local/share/android-ndk
   ├─ Java SDK: /Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home
   └─ Gradle: Use Latest Gradle (checked)
```

### Android 매니페스트 설정

```xml
<!-- res://android/build/AndroidManifest.xml -->
<manifest>
    <!-- 필수 권한 -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    
    <!-- 필수 기능 -->
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="com.google.ar.core" android:required="false" />
    
    <!-- ARCore 지원 -->
    <meta-data
        android:name="com.google.ar.core"
        android:value="required" />
</manifest>
```

---

## 3. iOS 환경 설정

### Xcode 설정

```bash
# 확인:
$ xcode-select --print-path
# 예상: /Applications/Xcode.app/Contents/Developer

$ swift --version
# 예상: swift-driver version 1.x.x

# 미설치 시:
xcode-select --install
```

### Godot iOS Export 설정

```
Editor → Project → Project Settings → Export
└─ iOS
   ├─ Min Version: 14.3
   ├─ Team ID: [Apple 개발자 계정 Team ID]
   └─ Signing Certificate: [자신의 인증서]
```

### iOS Info.plist 설정

```xml
<!-- res://ios/Info.plist -->
<dict>
    <!-- 카메라 권한 설명 -->
    <key>NSCameraUsageDescription</key>
    <string>AR 기능을 위해 카메라 접근이 필요합니다</string>
    
    <!-- 위치 권한 설명 -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>게임 영토 시스템을 위해 위치 정보가 필요합니다</string>
    
    <!-- ARKit 지원 -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>arkit</string>
    </array>
</dict>
```

---

## 4. ARCore/ARKit SDK 설정

### ARCore SDK 설치 (Android)

```bash
# ARCore SDK는 Godot에서 플러그인으로 관리
# 확인:
$ ls -la ~/.godot/addon_cache/ | grep -i ar

# 또는 Godot 에디터에서:
# AssetLib → "OpenXR" 검색 → "Godot OpenXR Vendors" 설치
```

### ARKit (iOS)

```
iOS 14.3 이상 기본 내장
Godot에서 자동 지원 (XR 플러그인 활성화 후)
```

---

## 5. 테스트 기기 준비

### Android 기기

```bash
# 기기 연결 확인:
$ adb devices
# 예상 출력:
# List of attached devices
# emulator-5554  device
# 또는
# 192.168.1.100:5555 device

# 드라이버 설치 (필요시):
# → USB 디버깅 활성화 (기기 설정 → 개발자 옵션)

# 테스트 권장 기기:
✅ Snapdragon 8 (Galaxy S24, S23)
✅ Snapdragon 6 (Galaxy A54, A53)
⚠️  저사양은 나중에 테스트
```

### iOS 기기

```bash
# 연결 확인:
$ system_profiler SPUSBDataType | grep -i apple

# Xcode에서 기기 등록:
# Xcode → Window → Devices and Simulators → [기기 등록]

# 테스트 권장 기기:
✅ iPhone 12 Pro+ (LiDAR 포함, ARKit 최고 성능)
✅ iPhone 13/14/15 (일반)
⚠️  iPhone X/11 이후 권장
```

---

## 6. 버전 관리 (Git)

### Git 설정 확인

```bash
$ git config --global user.name "ceo"
$ git config --global user.email "dev@zoit.co.kr"

$ git status
# On branch main
# nothing to commit, working tree clean
```

### 브랜치 확인

```bash
$ git log --oneline -1
# 0097bbe feat: Vision System 제1 목표 설정 및 Sprint 1 계획 수립
```

---

## 7. IDE/에디터 설정

### VS Code (선택사항)

```json
// .vscode/settings.json
{
    "gdscript.lsp_server_port": 6005,
    "[gdscript]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "efoerdelyak.gdscript-formatter"
    },
    "search.exclude": {
        "**/addons/**": true,
        "**/.godot/**": true
    }
}
```

### Godot 에디터 설정

```
Editor → Editor Layout: 2 Columns (권장)
Editor → Appearance: Dark (권장)
Debug → Debugger: GDScript Debugger 활성화
Output: Both Console and Debug Output 확인
```

---

## 8. 성능 모니터링 도구 준비

### Godot 내장 프로파일러

```
Debug → Debugger → Profiler 탭
├─ Frame Time (ms)
├─ Memory (MB)
├─ Rendering (Draw Calls)
└─ Physics
```

### Android Profiler

```
Android Studio → Profiler 탭
├─ CPU: CPU 사용률 모니터링
├─ Memory: 메모리 누수 감지
├─ Energy: 배터리 소비
└─ Network: 네트워크 활동
```

### 디버그 로그 확인

```bash
# Android logcat
$ adb logcat | grep -i "godot\|ar\|camera"

# iOS Console (Xcode)
# Xcode → Window → Devices and Simulators → [기기] → Console
```

---

## 9. 최종 체크리스트

### 개발 시작 전 확인 항목

```
엔진:
  ☑ Godot 4.6 설치 확인
  ☑ XR 플러그인 활성화
  ☑ Export 템플릿 다운로드
  ☑ project.godot 설정 확인

Android:
  ☑ Android SDK 설치 (API 33)
  ☑ NDK 설치
  ☑ Java 17 설치
  ☑ Godot Android Export 설정
  ☑ 테스트 기기 연결 (adb devices)
  ☑ USB 디버깅 활성화
  ☑ AndroidManifest.xml 권한 설정

iOS:
  ☑ Xcode 설치 (최신)
  ☑ Command Line Tools 설정
  ☑ Team ID 설정
  ☑ Info.plist 설정
  ☑ 테스트 기기 등록 (선택사항)

Git:
  ☑ Git 설정 확인
  ☑ main 브랜치 최신 상태
  ☑ 커밋 준비 완료

모니터링:
  ☑ Godot 프로파일러 테스트
  ☑ logcat/Console 확인 방법 숙지
  ☑ Android Profiler 열기 (Android 기기)
```

---

## 10. 문제 해결

### 문제: "adb not found"

```bash
해결:
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
# ~/.zshrc에 추가하고 source ~/.zshrc
```

### 문제: "NDK not found"

```bash
해결:
# Godot Editor → Project Settings → Android
# NDK Path를 정확히 설정:
# /usr/local/share/android-ndk
```

### 문제: "ARCore SDK 못 찾음"

```
해결:
1. Godot 에디터에서 AssetLib 열기
2. "OpenXR" 검색
3. "Godot OpenXR Vendors" 설치
4. Reimport 클릭
```

### 문제: iOS 빌드 실패

```
해결:
1. Xcode → Product → Clean Build Folder
2. Godot → 신규 Export 생성
3. Team ID, Signing Certificate 확인
```

---

## 히스토리

- **2026-05-21**: 개발 환경 체크리스트 작성

