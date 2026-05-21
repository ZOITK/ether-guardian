# 프로젝트명: 에테르 가디언 (Ether Guardian) - AR 공간 점유 슈팅

본 문서는 Godot 4.x 엔진과 Godot XR Tools를 활용한 AR 기반 영토 점유 게임의 프로토타입 설계서입니다.

---

## 1. 시놉시스 (Synopsis)

### 1.1 배경
현실 세계 위에 겹쳐진 또 다른 차원 '에테르 월드'의 균열이 발생했습니다. 플레이어는 가디언이 되어 현실 공간을 침식하는 차원 몬스터를 장거리 무기로 사냥하고, 정화된 지역에 '에테르 추출기'를 설치하여 영토를 점유해야 합니다.

### 1.2 핵심 루프
1. **스캔(Scan)**: 카메라로 주변 지형(바닥, 벽)을 인식하여 물리 공간 매핑.
2. **조준/사격(Shoot)**: 원거리 투사체 무기를 이용해 3D 공간에 배치된 몹 사냥.
3. **점유(Claim)**: 몹이 사라진 지점에 가상의 깃발(추출기)을 세워 영토 소유권 주장.
4. **방어(Defend)**: 점유한 땅에 자동 방어 터렛을 배치하여 타 플레이어의 침입 대비.

---

## 2. 아키텍처 (Architecture)

### 2.1 기술 스택
* **Engine**: Godot 4.x (Mobile Renderer - Vulkan/GLES3)
* **AR Framework**: Godot XR Tools (OpenXR 기반)
* **Platform SDK**: ARCore (Android) / ARKit (iOS)
* **Core Logic**: GDScript (UI 및 일반 로직) + GDExtension/C++ (탄도 계산 및 정밀 데이터 처리)
* **Backend**: Go/C++ Socket Server (영토 데이터 실시간 동기화)

### 2.2 시스템 구조
* **XR Origin 3D**: 카메라 위치 및 추적의 루트.
    * **XR Camera 3D**: 실시간 카메라 영상 패스스루 및 뷰포트.
    * **Weapon Handler**: 조준점(Reticle) 및 발사 로직 담당.
* **Spatial Manager**: ARCore/ARKit에서 넘어온 평면 데이터를 `StaticBody3D`로 변환하여 물리 충돌체 생성.
* **Persistence Layer**: Geospatial API 연동을 통한 GPS 기반 영토 위치 저장.

---

## 3. 프로토타입 상세 설계 (Technical Design)

### 3.1 공간 인식 및 물리 엔진 연동
Godot XR Tools의 `XRSpatialModifier`를 참고하여 실시간 메싱 구현.
* **Floor/Wall Detection**: ARCore/ARKit이 식별한 평면 데이터를 `CollisionShape3D`로 실시간 생성.
* **Occlusion**: 인식된 평면을 투명한 `OccluderInstance3D`로 설정하여 몬스터가 벽 뒤로 숨는 효과 구현.

### 3.2 장거리 사격 시스템 (Projectile System)
* **Raycasting**: 화면 중앙에서 `Camera.project_ray_normal()`을 실행하여 충돌 지점 계산.
* **Ballistics**: 단순 직선 레이저가 아닌, 중력 가속도가 적용된 투사체(Rigidbody3D) 발사.
* **Hit Detection**: 몬스터 노드에 `Area3D`를 부착하여 투사체와의 충돌 및 대미지 처리.

### 3.3 영토 점유 로직 (Territory Claim)
* **Anchor System**: 사냥 완료 지점에 `XRAnchor3D`를 생성하여 월드 좌표 고정.
* **State Management**: 
    * `Vacant`: 주인 없는 땅.
    * **Combat**: 몹 스폰 및 전투 중.
    * **Claimed**: 플레이어 소유 (에테르 추출기 모델 렌더링).

### 3.4 주요 노드 구조 (Godot Scene Tree)
```text
Main (Node3D)
├── XROrigin3D (XRTools 연동)
│   ├── XRCamera3D (Pass-through)
│   └── WeaponStation (Node3D - 위치 고정)
│       ├── MeshInstance3D (총기 모델)
│       └── Muzzle (Marker3D)
├── ARManager (Script: ARCore/ARKit Plugin Interface)
├── WorldObjects (Node3D: 생성된 몬스터 및 점유 깃발 관리)
└── CanvasLayer (HUD: 에테르 보유량, 사거리 정보)
