# 에테르 가디언 - 프로젝트 초기 설정 가이드

## 1. 개발 환경 준비 (macOS 기준)

### 1.1 필수 도구 설치

```bash
# Homebrew로 필수 도구 설치
brew install openjdk@17 android-sdk android-ndk
```

### 1.2 환경 변수 설정

```bash
# ~/.zshrc 또는 ~/.bash_profile에 추가
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export ANDROID_SDK_ROOT=/usr/local/share/android-sdk
export ANDROID_NDK_ROOT=/usr/local/share/android-ndk
export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
```

설정 후:
```bash
source ~/.zshrc
```

### 1.3 Godot 4.x 설치

```bash
# /Applications/Godot.app에 설치됨 (또는 brew)
# 또는 https://godotengine.org에서 다운로드
```

---

## 2. Godot 프로젝트 열기

### 2.1 Godot 에디터에서 프로젝트 로드

```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/zoitceo/work/godot/Ether-Guardian
```

또는 Godot 에디터를 열고:
1. **프로젝트 선택**
2. 경로: `/Users/zoitceo/work/godot/Ether-Guardian`
3. **열기**

### 2.2 프로젝트 첫 시작

에디터가 열리면:
- `scenes/main.tscn`을 더블클릭하여 메인 씬 열기
- 재생 버튼(▶️)으로 씬 테스트

---

## 3. ARCore/ARKit 연동 준비

### 3.1 OpenXR 플러그인 설치

에디터 메뉴:
1. **AssetLib** (또는 **지정됨**)
2. "OpenXR" 검색
3. **Godot OpenXR Vendors** 다운로드
4. **Install** 클릭

### 3.2 Project Settings에서 XR 설정

**Project → Project Settings:**

```
XR:
├─ OpenXR:
│  ├─ enabled = ON
│  ├─ default_action_map = res://xr_default_action_map.tres
│  └─ setup_action_map = ON
```

### 3.3 Android 익스포트 템플릿 설정

1. **Editor → Manage Export Templates**
2. Godot 4.6 버전 다운로드
3. **추출** 클릭

---

## 4. Android 빌드 준비

### 4.1 Android Keystore 생성

Android 앱을 서명하기 위한 키스토어:

```bash
keytool -genkey -v \
  -keystore ~/ether_guardian.keystore \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias ether_guardian
```

### 4.2 Export Settings 설정

**File → Export:**

1. **Add...** → Android 선택
2. **General:**
   - Package Name: `com.example.ether_guardian`
   - Unique Name: `Ether Guardian`

3. **Android:**
   - Min SDK: 26
   - Target SDK: 33
   - Permissions: `CAMERA`, `INTERNET`, `ACCESS_FINE_LOCATION`

4. **Keystore:**
   - Release Keystore: ~/ether_guardian.keystore
   - Release User: ether_guardian
   - Release Password: [생성할 때 입력한 비밀번호]

### 4.3 Export 테스트

```bash
# Android APK 빌드
/Applications/Godot.app/Contents/MacOS/Godot \
  --export-release Android \
  /Users/zoitceo/work/godot/Ether-Guardian/export/ether_guardian.apk
```

---

## 5. 데스크톱 테스트 (AR 없이)

### 5.1 기본 기능 테스트 (macOS/Windows)

```bash
# 프로젝트 실행
/Applications/Godot.app/Contents/MacOS/Godot \
  --path /Users/zoitceo/work/godot/Ether-Guardian
```

**테스트 가능한 기능:**
- ✅ 카메라 입력 (더미)
- ✅ 사격 시스템 (마우스 클릭)
- ✅ 투사체 렌더링
- ✅ 성능 모니터링 (HUD)
- ❌ AR 평면 감지 (Android/iOS만)
- ❌ 네트워크 동기화 (백엔드 필요)

### 5.2 마우스 조작

| 조작 | 동작 |
|------|------|
| 마우스 클릭 | 투사체 발사 |
| WASD | 카메라 이동 (미구현) |
| 마우스 드래그 | 카메라 회전 (미구현) |

---

## 6. ARCore 연동 테스트 (Android)

### 6.1 실제 기기에 배포

```bash
# 기기 연결 확인
adb devices

# APK 설치
adb install export/ether_guardian.apk

# 로그 확인
adb logcat | grep -i "ether\|ar\|xr"
```

### 6.2 권한 허용

앱 실행 후 다음 권한 허용:
- ✅ 카메라 접근
- ✅ 위치 정보
- ✅ 인터넷

### 6.3 디버그 정보 확인

화면에 표시되는 HUD:
```
[성능 모니터링]
FPS: 60 / 60
Frame Time: 16.67 ms
Memory: 350 MB
AR: TRACKING | Planes: 5
```

---

## 7. 성능 프로파일링

### 7.1 Godot 디버거 연결

1. **Debug → Debugger** 탭 열기
2. 기기 또는 시뮬레이터와 자동 연결

### 7.2 성능 데이터 수집

**Profiler 탭:**
- **Frame Time**: 각 프레임 소비 시간
- **Memory**: 메모리 사용량 추적
- **Rendering**: 렌더링 성능 분석

### 7.3 Android Profiler (선택사항)

```bash
# Android Studio의 Profiler 도구
# 또는 Godot의 내장 프로파일러 사용
```

---

## 8. 문제 해결

### 8.1 OpenXR 초기화 실패

**증상:** "[ARManager] OpenXR 초기화 실패!"

**해결:**
1. OpenXR 플러그인 재설치
2. Project Settings에서 XR 설정 확인
3. 에디터 재시작

### 8.2 카메라 권한 거부

**증상:** 검은 화면

**해결:**
```bash
# 권한 재설정
adb shell pm reset-permissions com.example.ether_guardian
adb shell pm grant com.example.ether_guardian android.permission.CAMERA
adb shell pm grant com.example.ether_guardian android.permission.INTERNET
```

### 8.3 프레임 드롭 (FPS < 30)

**증상:** 끊어지는 영상

**해결:**
1. 스크립트/성능 프로파일러로 병목 지점 확인
2. 불필요한 렌더링 최소화
3. 해상도 낮추기 (AR 설정에서)

---

## 9. 다음 단계

### Phase 1 완료 후 (1-2주)
- [ ] ARCore 평면 감지 테스트 (Android 실제 기기)
- [ ] 메싱 성능 벤치마크
- [ ] FPS 목표 달성 확인 (60FPS)

### Phase 2 시작 (2주)
- [ ] 몬스터 AI 기본 로직
- [ ] 투사체 충돌 시스템
- [ ] 점유 로직 (영토 표시)

### Phase 3 시작 (3주)
- [ ] 백엔드 서버 연동
- [ ] 멀티플레이 동기화
- [ ] PvP 기본 테스트

---

## 10. 유용한 명령어

```bash
# Godot 프로젝트 실행 (헤드리스)
godot --path . -v

# 특정 씬 열기
godot --path . -e scenes/main.tscn

# 디버그 모드 실행
godot --path . -d

# 내보내기 (명령줄)
godot --path . --export-release Android export/ether_guardian.apk

# 로그 필터 (macOS)
log stream --predicate 'process == "Godot"' --level debug
```

---

**작성일**: 2026-04-15
**마지막 업데이트**: 2026-04-15
**상태**: 초기 설정 완료
