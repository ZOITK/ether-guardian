extends Node3D

## 평면 감지기: 다양한 평면 유형 분류 및 필터링
## 역할: ARCore/ARKit 평면 데이터 → 게임 친화적 필터링
## 작성일: 2026-05-21

# 평면 타입
enum PlaneType { FLOOR, CEILING, WALL, TABLE, UNKNOWN }

var ar_manager: Node3D
var detected_planes: Dictionary = {}  # ID → FilteredPlaneData

func _ready() -> void:
	print("[Plane Detector] _ready() 시작")
	print("[Plane Detector] 노드 이름: %s" % name)
	print("[Plane Detector] get_parent(): %s" % get_parent())

	ar_manager = get_parent()
	print("[Plane Detector] ar_manager: %s" % ar_manager)

	if ar_manager and ar_manager.has_signal("plane_detected"):
		ar_manager.plane_detected.connect(_on_plane_detected)
		print("[Plane Detector] ✅ plane_detected 신호 연결 완료")
	else:
		print("[Plane Detector] ❌ ar_manager 또는 신호 없음")

## 평면 감지 콜백
func _on_plane_detected(plane_data: Dictionary) -> void:
	var filtered = _filter_and_classify_plane(plane_data)

	if filtered["is_valid"]:
		detected_planes[plane_data["id"]] = filtered
		print("[Plane Detector] 평면 분류: %s (정확도: %.1f%%)" % [
			PlaneType.keys()[filtered["type"]],
			filtered["confidence"] * 100
		])

## 평면 필터링 및 분류
func _filter_and_classify_plane(plane_data: Dictionary) -> Dictionary:
	var vertices = plane_data["vertices"]

	# 최소 정점 수 확인 (삼각형 이상)
	if vertices.size() < 3:
		return {"is_valid": false}

	# 평면 법선 계산
	var normal = _calculate_plane_normal(vertices)

	# 평면 타입 분류
	var plane_type = _classify_plane_type(normal)

	# 신뢰도 계산 (향후 OpenCV와 비교)
	var confidence = 0.85  # 기본값 (85%)

	return {
		"is_valid": true,
		"id": plane_data["id"],
		"type": plane_type,
		"normal": normal,
		"vertices": vertices,
		"center": plane_data["center"],
		"confidence": confidence,
		"timestamp": plane_data["timestamp"]
	}

## 평면 법선 벡터 계산
func _calculate_plane_normal(vertices: PackedVector3Array) -> Vector3:
	if vertices.size() < 3:
		return Vector3.UP

	var v0 = vertices[1] - vertices[0]
	var v1 = vertices[2] - vertices[0]
	return v0.cross(v1).normalized()

## 평면 타입 분류 (법선 벡터 기반)
func _classify_plane_type(normal: Vector3) -> int:
	# 평면 법선과 업 벡터(Y축) 사이의 각도
	var angle_to_up = normal.angle_to(Vector3.UP)

	# 수평면 (바닥, 천장)
	if angle_to_up < 0.2 or angle_to_up > 2.94:  # 약 ±11.5도
		# 바닥 vs 천장 판별
		return PlaneType.FLOOR if normal.y > 0 else PlaneType.CEILING

	# 수직면 (벽)
	elif angle_to_up > 1.3 and angle_to_up < 1.8:  # 약 74-103도
		return PlaneType.WALL

	# 테이블 같은 경사면 (테이블)
	elif angle_to_up > 0.4 and angle_to_up < 1.1:  # 약 23-63도
		return PlaneType.TABLE

	else:
		return PlaneType.UNKNOWN

## 캐시된 평면 반환
func get_plane(plane_id: int) -> Dictionary:
	return detected_planes.get(plane_id, {})

## 타입별 평면 반환
func get_planes_by_type(plane_type: int) -> Array:
	var result = []
	for plane in detected_planes.values():
		if plane["type"] == plane_type:
			result.append(plane)
	return result
