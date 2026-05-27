extends Node3D

## [클래스 설명]
## AR 매니저(AR Manager): Android 및 iOS 모바일 기기의 AR 환경을 관리합니다.
## ARCore(Android) / ARKit(iOS) 플러그인과 통합하여 실시간 평면 감지를 수행합니다.
## 플러그인이 없으면 더미 평면으로 폴백합니다.
## 작성일: 2026-05-21
## 수정일: 2026-05-27 (ARCore 플러그인 통합 준비)

# 평면이 감지되었을 때 발생하는 신호 (평면의 정점, 중심점 등의 메타데이터 전달)
signal plane_detected(plane_data: Dictionary)

# 카메라 피드를 관리하는 CameraManager 노드의 참조 변수
var camera_manager: Node

# ARCore 플러그인 (Android)
var arcore_plugin: Object = null
var has_arcore: bool = false

# ARKit 플러그인 (iOS)
var arkit_plugin: Object = null
var has_arkit: bool = false

# 시뮬레이션용 변수: 감지된 누적 평면의 개수
var plane_counter: int = 0
# 시뮬레이션용 변수: 새로운 더미 평면 생성을 위한 프레임 카운터
var plane_spawn_counter: int = 0
# 감지된 평면들의 데이터를 ID별로 보관하는 사전(Dictionary)
var detected_planes: Dictionary = {}

# 현재 AR 모드: "arcore", "arkit", "simulation"
var ar_mode: String = "simulation"

## [함수 설명]
## _ready(): 노드가 씬 트리에 진입할 때 호출되는 초기화 함수입니다.
## AR 플러그인 초기화 및 CameraManager 참조를 설정합니다.
func _ready() -> void:
	print("[AR Manager] AR 시스템 초기화")

	# 카메라 매니저 연결
	camera_manager = get_node("../../../../CameraManager")
	if not camera_manager:
		print("[AR Manager] ⚠️ 카메라 매니저 없음")
	else:
		print("[AR Manager] 카메라 매니저 연결됨")

	# AR 플러그인 초기화
	_initialize_ar_plugins()

	print("[AR Manager] ✅ AR 초기화 완료 (모드: %s)" % ar_mode)

## [함수 설명]
## _initialize_ar_plugins(): 사용 가능한 AR 플러그인을 초기화합니다.
## Android: ARCore, iOS: ARKit, 미지원: Simulation
func _initialize_ar_plugins() -> void:
	# Android: ARCore 플러그인 확인
	if OS.get_name() == "Android":
		if Engine.has_singleton("ARCorePlugin"):
			arcore_plugin = Engine.get_singleton("ARCorePlugin")
			has_arcore = true
			ar_mode = "arcore"
			print("[AR Manager] ✅ ARCore 플러그인 감지됨")
			_init_arcore()
		else:
			print("[AR Manager] ⚠️ ARCore 플러그인 없음 - 시뮬레이션 모드 사용")
			ar_mode = "simulation"

	# iOS: ARKit 플러그인 확인
	elif OS.get_name() == "iOS":
		if Engine.has_singleton("ARKitPlugin"):
			arkit_plugin = Engine.get_singleton("ARKitPlugin")
			has_arkit = true
			ar_mode = "arkit"
			print("[AR Manager] ✅ ARKit 플러그인 감지됨")
			_init_arkit()
		else:
			print("[AR Manager] ⚠️ ARKit 플러그인 없음 - 시뮬레이션 모드 사용")
			ar_mode = "simulation"

	# PC/Other: 항상 시뮬레이션
	else:
		ar_mode = "simulation"
		print("[AR Manager] 시뮬레이션 모드 (플랫폼: %s)" % OS.get_name())

## [함수 설명]
## _init_arcore(): ARCore 플러그인 세션을 초기화합니다. (Android 전용)
func _init_arcore() -> void:
	if not has_arcore:
		return

	# ARCore 세션 초기화
	# 예: arcore_plugin.initialize()
	print("[AR Manager] ARCore 세션 초기화...")
	# TODO: ARCore API 호출 (플러그인 빌드 후)

## [함수 설명]
## _init_arkit(): ARKit 세션을 초기화합니다. (iOS 전용)
func _init_arkit() -> void:
	if not has_arkit:
		return

	# ARKit 세션 초기화
	# 예: arkit_plugin.initialize()
	print("[AR Manager] ARKit 세션 초기화...")
	# TODO: ARKit API 호출 (플러그인 빌드 후)

## [함수 설명]
## _process(delta): 매 프레임마다 호출되는 프로세스 함수입니다.
## AR 모드에 따라 다르게 평면을 감지합니다.
func _process(delta: float) -> void:
	match ar_mode:
		"arcore":
			# ARCore 플러그인에서 평면 감지 (TODO: 플러그인 빌드 후 구현)
			pass
		"arkit":
			# ARKit 플러그인에서 평면 감지 (TODO: 플러그인 빌드 후 구현)
			pass
		"simulation":
			# 시뮬레이션: 3초마다 더미 평면 생성
			plane_spawn_counter += 1
			if plane_spawn_counter >= 180:  # 3초 (60 FPS 기준)
				_generate_dummy_plane()
				plane_spawn_counter = 0

## [함수 설명]
## _generate_dummy_plane(): 가상의 평면 데이터를 무작위로 생성하여 시뮬레이션을 구동하는 함수입니다.
## 3D 공간상의 랜덤한 정점 배열과 중심점을 계산한 후 plane_detected 신호를 방출하여 mesh_generator가 시각화하도록 돕습니다.
func _generate_dummy_plane() -> void:
	plane_counter += 1

	# 임의의 평면 크기 및 3D 좌표 스폰 범위 설정
	var width = randf_range(0.5, 3.0)
	var height = randf_range(0.5, 3.0)
	var x = randf_range(-2.0, 2.0)
	var y = randf_range(-1.0, 1.0)
	var z = randf_range(0.5, 3.0)

	# 평면을 이루는 4개의 정점 (사각형 구조) 계산
	var vertices = PackedVector3Array([
		Vector3(x - width/2, y, z),           # 왼쪽 위
		Vector3(x + width/2, y, z),           # 오른쪽 위
		Vector3(x + width/2, y - height, z), # 오른쪽 아래
		Vector3(x - width/2, y - height, z)  # 왼쪽 아래
	])

	# 평면의 수학적 중심점 계산
	var center = Vector3(x, y - height/2, z)

	# 평면 정보를 담은 Dictionary 메타데이터 생성
	var plane_data = {
		"id": plane_counter,
		"vertices": vertices,
		"center": center,
		"timestamp": Time.get_ticks_msec()
	}

	# 사전형 캐시에 저장
	detected_planes[plane_counter] = plane_data
	print("[AR Manager] 더미 평면 생성: ID=%d, 위치=(%.1f, %.1f, %.1f)" % [plane_counter, x, y, z])

	# 평면 감지 신호를 전파하여 PlaneDetector 및 MeshGenerator가 처리할 수 있도록 함
	plane_detected.emit(plane_data)
