extends Node3D

## AR 매니저: ARCore/ARKit 통합 관리
## 역할: 플랫폼별 AR 세션 초기화, 평면 감지, 상태 관리
## 작성일: 2026-05-21

# 신호
signal plane_detected(plane_data: Dictionary)
signal plane_updated(plane_data: Dictionary)
signal plane_removed(plane_id: int)
signal ar_session_initialized
signal ar_session_failed(error: String)

# AR 세션 상태
enum ARState { UNINITIALIZED, INITIALIZING, RUNNING, PAUSED, FAILED }

var ar_state: ARState = ARState.UNINITIALIZED
var platform_name: String = ""
var ar_session = null
var plane_cache: Dictionary = {}  # ID → PlaneData

func _ready() -> void:
	platform_name = OS.get_name()
	_initialize_ar_session()

## AR 세션 초기화
func _initialize_ar_session() -> void:
	ar_state = ARState.INITIALIZING

	if platform_name == "Android":
		_initialize_arcore()
	elif platform_name == "iOS":
		_initialize_arkit()
	else:
		ar_session_failed.emit("Unsupported platform: %s" % platform_name)
		ar_state = ARState.FAILED

## Android ARCore 초기화
func _initialize_arcore() -> void:
	print("[AR Manager] ARCore 초기화 중...")

	# TODO: ARCore SDK 초기화
	# - 카메라 권한 요청
	# - ARCore 세션 생성
	# - 평면 감지 활성화

	ar_session_initialized.emit()
	ar_state = ARState.RUNNING

## iOS ARKit 초기화
func _initialize_arkit() -> void:
	print("[AR Manager] ARKit 초기화 중...")

	# TODO: ARKit 세션 생성
	# - 카메라 권한 요청 (NSCameraUsageDescription)
	# - ARSession 생성
	# - planeDetection 활성화

	ar_session_initialized.emit()
	ar_state = ARState.RUNNING

func _process(delta: float) -> void:
	if ar_state != ARState.RUNNING:
		return

	# TODO: 매 프레임 평면 업데이트 쿼리
	# _update_planes()

## 평면 감지 업데이트 (ARCore/ARKit에서 호출)
func _on_plane_detected(plane_id: int, plane_vertices: PackedVector3Array) -> void:
	var plane_data = {
		"id": plane_id,
		"vertices": plane_vertices,
		"center": _calculate_plane_center(plane_vertices),
		"timestamp": Time.get_ticks_msec()
	}

	plane_cache[plane_id] = plane_data
	plane_detected.emit(plane_data)

	print("[AR Manager] 평면 감지: ID=%d, 정점=%d개" % [plane_id, plane_vertices.size()])

## 평면 중심 계산
func _calculate_plane_center(vertices: PackedVector3Array) -> Vector3:
	var center = Vector3.ZERO
	for vertex in vertices:
		center += vertex
	return center / vertices.size() if vertices.size() > 0 else Vector3.ZERO

## 캐시된 평면 반환
func get_plane(plane_id: int) -> Dictionary:
	return plane_cache.get(plane_id, {})

## 모든 평면 반환
func get_all_planes() -> Array:
	return plane_cache.values()
