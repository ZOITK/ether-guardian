extends Node3D

## 메시 생성기: 평면 데이터 → Godot Mesh 시각화
## 작성일: 2026-05-21

var ar_manager: Node
var plane_detector: Node3D
var status_label: Label
var mesh_instances: Dictionary = {}
var mesh_generation_times: Array = []
var mesh_count: int = 0

func _ready() -> void:
	print("[Mesh Generator] _ready() 시작")
	plane_detector = get_parent()
	ar_manager = plane_detector.get_parent()
	status_label = get_node_or_null("../../../DebugLabel")
	print("[Mesh Generator] status_label: %s" % status_label)

	if ar_manager and ar_manager.has_signal("plane_detected"):
		ar_manager.plane_detected.connect(_on_plane_detected)
		print("[Mesh Generator] ✅ plane_detected 신호 연결 완료")

## 평면 감지 → 메시 생성
func _on_plane_detected(plane_data: Dictionary) -> void:
	print("[Mesh Generator] _on_plane_detected 호출됨! ID=%d" % plane_data["id"])
	mesh_count += 1

	if status_label:
		status_label.text = "[메시 생성 중...]\n생성된 평면: %d개" % mesh_count

	var start_time = Time.get_ticks_msec()

	# 간단한 SphereMesh 사용
	var mesh = SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0

	# MeshInstance3D 생성
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position = plane_data["center"]
	mesh_instance.name = "Plane_%d" % plane_data["id"]

	print("[Mesh Generator] SphereMesh 생성, 위치: %s" % mesh_instance.position)

	# 반투명 파란색 재료
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.4, 1.0, 0.7)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material

	# 노드 추가
	add_child(mesh_instance)
	mesh_instances[plane_data["id"]] = mesh_instance

	print("[Mesh Generator] ✅ MeshInstance3D 추가, 자식 수: %d" % get_child_count())

	var elapsed = Time.get_ticks_msec() - start_time
	mesh_generation_times.append(elapsed)

	if status_label:
		status_label.text = "[✅ 메시 생성 완료]\n평면 ID: %d | 총 개수: %d | 시간: %.1fms" % [
			plane_data["id"], mesh_count, elapsed
		]

func get_average_mesh_generation_time() -> float:
	if mesh_generation_times.is_empty():
		return 0.0
	var total = 0.0
	for time in mesh_generation_times:
		total += time
	return total / mesh_generation_times.size()

func get_performance_stats() -> Dictionary:
	return {
		"total_meshes": mesh_instances.size(),
		"avg_generation_time_ms": get_average_mesh_generation_time(),
		"max_generation_time_ms": mesh_generation_times.max() if not mesh_generation_times.is_empty() else 0.0
	}
