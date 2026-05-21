extends Node3D

## 메시 생성기: 평면 데이터 → Godot Mesh + StaticBody3D
## 역할: 감지된 평면을 게임 월드에 배치, 충돌 형태 설정
## 작성일: 2026-05-21

var plane_detector: Node3D
var mesh_instances: Dictionary = {}  # PlaneID → MeshInstance3D
var static_bodies: Dictionary = {}  # PlaneID → StaticBody3D

# 성능 측정
var mesh_generation_times: Array = []

func _ready() -> void:
	plane_detector = get_parent()
	if plane_detector.has_signal("plane_detected"):
		plane_detector.plane_detected.connect(_on_plane_detected)

## 평면 감지 → 메시 생성
func _on_plane_detected(plane_data: Dictionary) -> void:
	var start_time = Time.get_ticks_msec()

	# 메시 생성
	var mesh = _create_mesh_from_vertices(plane_data["vertices"])

	# StaticBody3D 생성 (충돌)
	var static_body = _create_static_body(mesh, plane_data["center"])

	# 저장
	mesh_instances[plane_data["id"]] = static_body.get_node("MeshInstance3D")
	static_bodies[plane_data["id"]] = static_body

	add_child(static_body)

	# 성능 측정
	var elapsed = Time.get_ticks_msec() - start_time
	mesh_generation_times.append(elapsed)

	print("[Mesh Generator] 메시 생성: ID=%d, 시간=%.2fms" % [plane_data["id"], elapsed])

## 꼭짓점 배열 → Mesh 변환
func _create_mesh_from_vertices(vertices: PackedVector3Array) -> Mesh:
	# 최소 정점 수 확인
	if vertices.size() < 3:
		return null

	# 삼각형 분해 (복잡한 다각형 → 삼각형 목록)
	var triangles = _triangulate_polygon(vertices)

	# Mesh 생성
	var mesh = Mesh.new()
	var surface_tool = SurfaceTool.new()

	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(0, triangles.size(), 3):
		var v0 = triangles[i]
		var v1 = triangles[i + 1]
		var v2 = triangles[i + 2]

		# 정점 추가
		surface_tool.add_vertex(v0)
		surface_tool.add_vertex(v1)
		surface_tool.add_vertex(v2)

	surface_tool.commit(mesh)
	return mesh

## 다각형 삼각분해 (단순 부채꼴 방식)
func _triangulate_polygon(vertices: PackedVector3Array) -> PackedVector3Array:
	var triangles = PackedVector3Array()

	for i in range(1, vertices.size() - 1):
		triangles.append(vertices[0])
		triangles.append(vertices[i])
		triangles.append(vertices[i + 1])

	return triangles

## StaticBody3D 생성 (충돌 + 시각화)
func _create_static_body(mesh: Mesh, position: Vector3) -> Node3D:
	var body = StaticBody3D.new()
	body.position = position

	# MeshInstance3D (시각화)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	# 반투명 재료 (오버레이 효과)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 1.0, 0.3)  # 파란색, 투명도 30%
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	body.add_child(mesh_instance)

	# CollisionShape3D (물리)
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	body.add_child(collision_shape)

	return body

## 평균 메시 생성 시간 반환
func get_average_mesh_generation_time() -> float:
	if mesh_generation_times.is_empty():
		return 0.0

	var total = 0.0
	for time in mesh_generation_times:
		total += time

	return total / mesh_generation_times.size()

## 성능 통계 반환
func get_performance_stats() -> Dictionary:
	return {
		"total_meshes": mesh_instances.size(),
		"avg_generation_time_ms": get_average_mesh_generation_time(),
		"max_generation_time_ms": mesh_generation_times.max() if not mesh_generation_times.is_empty() else 0.0,
		"memory_usage_mb": (mesh_instances.size() * 50) / 1024.0  # 대략 추정
	}
