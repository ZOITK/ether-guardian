# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6 (January 2026)
- **Language**: GDScript (주), C++ GDExtension (영상 처리 성능 최적화)
- **Rendering**: Mobile (Vulkan 우선, GLES3 폴백)
- **Physics**: Jolt (Godot 4.6 기본, 고성능 3D 물리)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: Android 26+ (API 26+), iOS 14.3+ (ARKit 지원)
- **Input Methods**: AR Camera (기본), Touch (UI 입력)
- **Primary Input**: AR Camera (위치, 방향, 깊이 기반 게임플레이)
- **Gamepad Support**: None
- **Touch Support**: Full (UI 메뉴, 설정, 인벤토리)
- **Platform Notes**: AR 플랫폼 의존성 (ARCore Android, ARKit iOS). 모바일 카메라 권한 필수. 위치 서비스 (GPS) 필수.

## Naming Conventions

- **Classes**: PascalCase (예: VisionProcessor, ARManager, MonsterAI)
- **Variables**: snake_case (예: vision_pipeline, frame_time, plane_count)
- **Signals/Events**: snake_case로 끝남 (예: plane_detected, monster_spawned, territory_claimed)
- **Files**: snake_case.gd (예: vision_processor.gd, ar_manager.gd)
- **Scenes/Prefabs**: PascalCase.tscn (예: MainScene.tscn, Monster.tscn)
- **Constants**: UPPER_SNAKE_CASE (예: MAX_PLANES, FPS_TARGET, MEMORY_CEILING_MB)

## Performance Budgets

- **Target Framerate**: 60 FPS (고성능 기기 Snapdragon 8), 45 FPS (중간 기기 Snapdragon 6), 30 FPS (저사양 기기)
- **Frame Budget**: 16.67ms @ 60FPS (입력→렌더링 완료)
- **Draw Calls**: <100 (목표, AR 오버레이 포함)
- **Memory Ceiling**: 500MB (앱 + 영상 버퍼 + 게임 오브젝트)

## Testing

- **Framework**: GDUnit4 (GDScript 단위 테스트)
- **Minimum Coverage**: 70% (게임로직), 90% (영상 처리, 네트워크, 물리)
- **Required Tests**: 
  - 영상 처리 파이프라인 (평면 감지, 메싱)
  - 물리 시뮬레이션 (충돌, 투사체)
  - 네트워크 동기화 (플레이어 위치, 영토 상태)
  - 게임 로직 (몬스터 AI, 터렛, 점유 시스템)

## Forbidden Patterns

- 싱글톤 남용 (DI 패턴 선호)
- 동기식 네트워크 호출 (비동기 Socket + 콜백 사용)
- 하드코딩된 게임플레이 값 (모두 config 파일로 외부화)
- 메인 스레드 블로킹 (영상 처리는 워커 스레드에서)

## Allowed Libraries / Addons

- **OpenCV 4.5+** (C++ GDExtension, 영상 전처리)
- **Godot XR Tools** (OpenXR 지원, ARCore/ARKit 통합)
- **GDUnit4** (테스트 프레임워크)
- **Go 1.21+** (백엔드 서버)
- **PostgreSQL 15+** (영토 데이터베이스)

## Architecture Decisions Log

- `adr-001-ar-platform-selection.md` — ARCore + ARKit + OpenCV 통합 전략
- `adr-002-vision-pipeline-gdextension.md` — C++ GDExtension 기반 영상 처리
- `adr-003-network-protocol-socket.md` — Go 소켓 서버 기반 네트워크 동기화
- `adr-004-mobile-rendering-strategy.md` — Vulkan 렌더러 + 적응형 해상도

## Engine Specialists

- **Primary**: godot-specialist (Godot 4.6 전체)
- **Language/Code Specialist**: godot-gdscript-specialist (GDScript)
- **Native Extension Specialist**: godot-gdextension-specialist (C++ GDExtension, OpenCV)
- **Shader Specialist**: godot-shader-specialist (Vulkan 셰이더)
- **UI Specialist**: godot-specialist (Godot UI Toolkit)
- **Additional Specialists**: network-programmer (Go 백엔드), performance-analyst (프로파일링)
- **Routing Notes**: 영상 처리 코드는 GDExtension 전문가에게, 게임 로직은 GDScript 전문가에게

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| .gd (GDScript) | godot-gdscript-specialist |
| .cpp, .h (C++ GDExtension) | godot-gdextension-specialist |
| .gdshader (셰이더) | godot-shader-specialist |
| .tscn (씬/프리팹) | godot-specialist |
| .go (Go 백엔드) | network-programmer |
| Architecture review | godot-specialist |
