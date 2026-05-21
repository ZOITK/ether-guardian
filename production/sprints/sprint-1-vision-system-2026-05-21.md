# Sprint 1: Vision System 검증

**기간**: 2026-05-21 ~ 2026-06-04 (2주)  
**목표**: ARCore/ARKit 평면 감지 구현 및 성능 벤치마크  
**상태**: 🟡 계획 단계

---

## 1. 스프린트 목표

### 주요 목표
```
ARCore/ARKit 기본 평면 감지만으로
→ 85%+ 정확도 달성 가능한가?
→ 60FPS 유지 가능한가?

이 두 질문에 YES 답변이 나오면,
게임 구현 진행 (전투 시스템, 네트워킹)
```

### 성공 정의 (Definition of Done)
```
✅ 실제 Android/iOS 기기에서 카메라 작동
✅ 바닥 평면 감지 정확도 >85% (테스트 환경)
✅ 프레임 레이트 60FPS (고성능) / 45FPS (중간)
✅ 메싱 생성 시간 <30ms
✅ 메모리 <300MB
✅ 모든 환경 테스트 완료 (실내/실외/야간)
```

### 실패 정의 (Fail Criteria)
```
❌ 정확도 <75% (게임 플레이 불가)
❌ FPS <30 (끊김 심함)
❌ 메싱 생성 >50ms (버벅거림)
❌ 카메라 권한 문제 (플랫폼 특화)
```

---

## 2. Sprint Tasks (Story 분해)

### Story 1: ARCore/ARKit 초기화 및 카메라 권한
**ID**: VISION-001  
**기간**: 2일 (Day 1-2)  
**우선순위**: 🔴 Critical (블로킹)

**요구사항**:
- [ ] Android 카메라 권한 요청 (`android.permission.CAMERA`)
- [ ] iOS 카메라 권한 요청 (`NSCameraUsageDescription`)
- [ ] ARCore 세션 생성 (Android API 26+)
- [ ] ARKit 세션 생성 (iOS 14.3+)
- [ ] 카메라 피드 실시간 표시

**수용 기준**:
```
✅ Android 기기: 카메라 권한 요청 후 화면에 라이브 피드 표시
✅ iOS 기기: 카메라 권한 요청 후 화면에 라이브 피드 표시
✅ 권한 거부 시: 사용자 가이드 표시 후 재요청
✅ 프레임 레이트: 최소 30FPS 이상
```

**기술 스택**:
```
- GDScript: src/vision/ar_manager.gd (AR 세션 관리)
- Plugin: Godot OpenXR (ARCore/ARKit 브리지)
- Platform: Android (ARCore SDK 1.40+), iOS (ARKit 4+)
```

**테스트 방법**:
```
1. Android 기기 연결
2. Godot 에디터에서 APK 빌드 및 실행
3. 카메라 권한 요청 대화 확인
4. 라이브 카메라 피드 표시 확인
5. iOS도 동일하게 테스트
```

---

### Story 2: 평면 감지 및 메싱 생성
**ID**: VISION-002  
**기간**: 2일 (Day 3-4)  
**우선순위**: 🔴 Critical  
**의존성**: VISION-001 완료 후

**요구사항**:
- [ ] ARCore detectPlanes() 호출 (Android)
- [ ] ARKit planeDetection 활성화 (iOS)
- [ ] 감지된 평면을 Godot Mesh로 변환
- [ ] StaticBody3D 생성 및 충돌 형태 설정
- [ ] 감지된 평면 시각적 표시 (반투명 오버레이)

**수용 기준**:
```
✅ 빈 공간(바닥만 있는 방): 3-5초 내 평면 감지
✅ 복잡한 환경(가구 많음): 5-10초 내 감지
✅ 감지 정확도: >85% (오류 판정 <15%)
✅ 메시 생성 시간: <30ms
✅ 메모리 증가: <50MB
```

**기술 스택**:
```
GDScript:
  - src/vision/plane_detector.gd (평면 감지 로직)
  - src/vision/mesh_generator.gd (Mesh 생성)
  - src/vision/scene_manager.gd (StaticBody3D 관리)

재사용:
  - camPlayer/main.gd 의 카메라 처리 참고
```

**테스트 방법**:
```
환경별 테스트:
1. 실내(밝은 방): 바닥 감지 확인
2. 실외(햇빛): 지면 감지 확인
3. 어두운 실내: 조명 부족 시 동작 확인

성능 측정:
  - Godot 프로파일러로 메싱 생성 시간 측정
  - 메모리 사용량 모니터링
```

---

### Story 3: 성능 벤치마크 및 최적화 검토
**ID**: VISION-003  
**기간**: 3일 (Day 5, Week 2 Day 1-2)  
**우선순위**: 🟡 High  
**의존성**: VISION-002 완료 후

**요구사항**:
- [ ] FPS 측정 (60FPS 목표 달성 여부)
- [ ] 프레임 타이밍 분석 (카메라 입력 → 렌더링)
- [ ] 메모리 프로파일링 (누수 여부)
- [ ] 배터리 소비 측정 (mA/h)
- [ ] 다중 환경 성능 테스트

**수용 기준**:
```
성능:
  ✅ 고성능 기기(Snapdragon 8): 60 FPS
  ✅ 중간 기기(Snapdragon 6): 45 FPS 이상
  ✅ 저사양 기기(Snapdragon 4): 30 FPS 이상

메모리:
  ✅ 기본 메모리: <200MB
  ✅ 평면 캐시(20개): <50MB
  ✅ 메모리 누수 없음 (30분 플레이)

배터리:
  ✅ 배터리 소비: <10%/10분 (목표: <5%)
```

**측정 도구**:
```
- Godot Engine.get_frames_per_second()
- OS.get_static_memory_usage()
- Android Profiler / Xcode Instruments
```

**결과 기록**:
```
docs/performance/vision-benchmark-2026-05-21.md 에 기록
```

---

### Story 4: 다중 환경 테스트 및 정확도 검증
**ID**: VISION-004  
**기간**: 2일 (Week 2 Day 3-4)  
**우선순위**: 🟡 High  
**의존성**: VISION-002 완료 후

**요구사항**:
- [ ] 실내 밝은 환경 테스트
- [ ] 실내 어두운 환경 테스트 (야간)
- [ ] 실외 햇빛 환경 테스트
- [ ] 반사 표면(거울, 유리) 테스트
- [ ] 복잡한 환경(가구 많음) 테스트

**정확도 평가 기준**:
```
테스트 환경마다:
  - 실제 평면 5개 설정
  - 감지된 평면과 매칭
  - 정확도 = (올바른 감지 / 실제 평면) × 100%

기준:
  ✅ 표준 환경: >90%
  ✅ 어려운 환경: >75%
  ✅ 실외: >85%
```

**문제 발견 시 대응**:
```
만약 정확도 <75%
  → VISION-005: OpenCV 전처리 필요
  → GDExtension C++ 검토

만약 FPS <30
  → VISION-006: 적응형 해상도 또는 최적화
```

---

## 3. Sprint Schedule (상세 일정)

### Week 1: 기초 구현

```
Day 1 (월)
├─ VISION-001 시작: 개발 환경 구축
│  ├─ Android Studio NDK 설정
│  ├─ iOS Xcode 프로젝트 생성
│  └─ 테스트 기기 연결
└─ /dev-story 로 첫 스토리 구현 시작

Day 2 (화)
├─ VISION-001: 카메라 권한 요청 완료
│  ├─ Android android.permission.CAMERA 구현
│  └─ iOS NSCameraUsageDescription 설정
└─ 테스트: 실제 기기에서 카메라 피드 확인

Day 3 (수)
├─ VISION-002 시작: 평면 감지
│  ├─ ARCore detectPlanes() 호출
│  ├─ ARKit planeDetection 활성화
│  └─ 콘솔 로그로 평면 감지 확인
└─ 테스트: "평면 감지 확인" (조용한 실내)

Day 4 (목)
├─ VISION-002: 메싱 생성
│  ├─ 감지된 평면 → Mesh 변환
│  ├─ StaticBody3D 생성
│  └─ 화면에 반투명 오버레이로 표시
└─ 테스트: 바닥이 반투명 메시로 표시되는지 확인

Day 5 (금)
├─ VISION-002: 통합 테스트
│  └─ 카메라 입력 → 평면 감지 → 메싱 표시 전체 검증
└─ VISION-003 준비: 성능 측정 도구 설정
```

### Week 2: 최적화 & 검증

```
Day 6 (월)
├─ VISION-003 시작: 성능 벤치마크
│  ├─ FPS 측정 (프로파일러)
│  ├─ 메모리 프로파일링
│  └─ 병목 지점 파악
└─ 로그 기록: docs/performance/vision-benchmark-2026-05-21.md

Day 7 (화)
├─ VISION-003: 최적화 검토
│  ├─ 60FPS 달성? → Yes: 계속
│  ├─ FPS <45? → GDExtension 검토
│  └─ 메모리 누수? → 리소스 해제 확인
└─ 의사결정: "OpenCV 통합 필요한가?"

Day 8 (수)
├─ VISION-004 시작: 다중 환경 테스트
│  ├─ 환경 A: 밝은 실내
│  ├─ 환경 B: 어두운 실내
│  ├─ 환경 C: 실외
│  └─ 정확도 측정 (각 환경마다 5회 반복)
└─ 결과 기록

Day 9 (목)
├─ VISION-004: 계속
│  ├─ 환경 D: 반사 표면
│  └─ 환경 E: 복잡한 환경 (가구)
└─ 정확도 분석

Day 10 (금)
├─ Sprint 1 검토 및 Gate Check
│  ├─ 모든 수용 기준 충족? → PASS/FAIL
│  ├─ PASS: Sprint 2 시작 (전투 시스템)
│  └─ FAIL: VISION-005/006 검토
└─ 최종 리포트: production/sprints/sprint-1-review.md
```

---

## 4. Gate Check (2주차 마지막 금요일)

### 통과 기준 (PASS)

```
반드시 모두 YES여야 함:

정확도:
  ✅ 표준 환경 >85%
  ✅ 모든 테스트 환경 >75% 이상

성능:
  ✅ 고성능 기기 60FPS
  ✅ 메모리 <300MB (베이스 + 버퍼)
  ✅ 메싱 생성 <30ms

기능:
  ✅ 카메라 라이브 피드 실시간 표시
  ✅ 평면 감지 및 메싱 완동작
  ✅ 오류 처리 (권한 거부, 시간 초과)
```

### 조건부 통과 (CONDITIONAL PASS)

```
다음 중 하나:
⚠️ FPS 45-59 (고성능 기기 미달)
  → Action: 적응형 해상도 적용 (Sprint 2)

⚠️ 정확도 80-84% (약간 미달)
  → Action: OpenCV 전처리 검토 (선택)

⚠️ 야간 정확도 <75%
  → Action: 조명 보조 피드백 UI 추가 (Sprint 3)
```

### 불통과 (FAIL)

```
다음 중 하나라도 발생 시 FAIL:
❌ 정확도 <75%
❌ FPS <30 (모든 환경)
❌ 카메라 작동 불가 (플랫폼 특화 문제)
❌ 메싱 생성 >50ms

FAIL 시:
  1. 원인 분석
  2. Architecture 재검토 (ADR-001/002 수정)
  3. Sprint 재계획
```

---

## 5. Sprint Risks (위험 요소)

| 위험 | 확률 | 영향 | 완화 전략 |
|------|------|------|---------|
| **ARCore 버전 호환성** | 🟡 중간 | 높음 | 최신 ARCore SDK 사용, 레거시 지원 확인 |
| **조명 부족(야간)** | 🟡 중간 | 높음 | 다양한 환경 미리 테스트 |
| **메모리 누수** | 🟢 낮음 | 중간 | 30분 연속 플레이 테스트, 프로파일러 모니터링 |
| **iOS LiDAR 없음** | 🟢 낮음 | 낮음 | ARKit만으로도 충분 (정확도 약 간소) |
| **NDK 빌드 실패** | 🟢 낮음 | 높음 | 미리 Android Studio 설정 검증 |

---

## 6. Resources & Tools

### 개발 도구
```
- Godot 4.6 (엔진)
- Android Studio (Android 빌드)
- Xcode (iOS 빌드)
- ARCore SDK 1.40+
- ARKit 4+
- Git (버전 관리)
```

### 테스트 기기
```
필수:
  - Android 고성능: Snapdragon 8 (Galaxy S24 등)
  - Android 중간: Snapdragon 6 (Galaxy A54 등)
  
선택:
  - iOS: iPhone 12 Pro+ (LiDAR)
  - iOS: iPhone 13/14 (일반)
```

### 성능 측정 도구
```
- Godot 내장 프로파일러
- Android Profiler (메모리, CPU)
- Xcode Instruments (iOS)
- adb logcat (디버그 로그)
```

---

## 7. Success Metrics

### 정량적 지표
```
FPS:
  Target: 60 FPS (고성능)
  Min: 45 FPS (중간)
  Low: 30 FPS (저사양)

정확도:
  Target: >90% (표준)
  Min: >85% (수용)
  Fail: <75%

메모리:
  Target: <300MB
  Max: <400MB
  Alert: >450MB

응답 시간:
  Target: <50ms (감지 → 렌더링)
```

### 정성적 지표
```
- 부드러운 카메라 피드
- 빠른 평면 감지 반응
- 안정적인 메싱 생성
- 사용자 만족도
```

---

## 8. Communication & Review

### Daily Standup
```
매일 오전 (선택사항):
  - 진행도
  - 블로킹 이슈
  - 오늘 계획
```

### Mid-Sprint Review (Day 5)
```
금요일 오후:
  - Week 1 완료도 확인
  - 예상 vs 실제 비교
  - Week 2 조정 필요 여부
```

### Sprint Review (Day 10)
```
금요일 오후:
  - 모든 스토리 완료 확인
  - 성능 벤치마크 결과 공유
  - Gate Check 판정
  - Sprint 2 계획 승인
```

---

## 히스토리

- **2026-05-21**: Sprint 1 계획 작성

