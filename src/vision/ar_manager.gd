extends Node3D

## AR 매니저: Android/iOS 카메라 통합 관리
## 작성일: 2026-05-21

signal plane_detected(plane_data: Dictionary)

var camera_manager: Node

# 평면 감지 (시뮬레이션)
var plane_counter: int = 0
var plane_spawn_counter: int = 0
var detected_planes: Dictionary = {}

func _ready() -> void:
	print("[AR Manager] AR 시스템 초기화")
	print("[AR Manager] 노드 이름: %s" % name)
	print("[AR Manager] 부모: %s" % get_parent())
	print("[AR Manager] 자식 수: %d" % get_child_count())
	for child in get_children():
		print("[AR Manager]   - 자식: %s (%s)" % [child.name, child.get_class()])

	# 카메라 매니저 참조
	camera_manager = get_node("../CameraManager")
	if not camera_manager:
		print("[AR Manager] ⚠️ 카메라 매니저 없음")
	else:
		print("[AR Manager] 카메라 매니저 연결됨")

	print("[AR Manager] ✅ AR 초기화 완료")

## 더미 평면 생성 (3초마다)
func _process(delta: float) -> void:
	plane_spawn_counter += 1
	if plane_spawn_counter >= 180:  # 3초 (60 FPS 기준)
		_generate_dummy_plane()
		plane_spawn_counter = 0

## 더미 평면 생성 (시뮬레이션)
func _generate_dummy_plane() -> void:
	plane_counter += 1

	# 임의의 평면 생성
	var width = randf_range(0.5, 3.0)
	var height = randf_range(0.5, 3.0)
	var x = randf_range(-2.0, 2.0)
	var y = randf_range(-1.0, 1.0)
	var z = randf_range(0.5, 3.0)

	# 평면 정점 (사각형)
	var vertices = PackedVector3Array([
		Vector3(x - width/2, y, z),           # 왼쪽 위
		Vector3(x + width/2, y, z),           # 오른쪽 위
		Vector3(x + width/2, y - height, z), # 오른쪽 아래
		Vector3(x - width/2, y - height, z)  # 왼쪽 아래
	])

	var center = Vector3(x, y - height/2, z)

	# 평면 데이터
	var plane_data = {
		"id": plane_counter,
		"vertices": vertices,
		"center": center,
		"timestamp": Time.get_ticks_msec()
	}

	detected_planes[plane_counter] = plane_data
	print("[AR Manager] 더미 평면 생성: ID=%d, 위치=(%.1f, %.1f, %.1f)" % [plane_counter, x, y, z])

	# 평면_감지 신호 emit
	plane_detected.emit(plane_data)
