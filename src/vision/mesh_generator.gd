extends Node3D

## 메시 생성기: 평면 데이터 → Godot Mesh + StaticBody3D
## 역할: 감지된 평면을 게임 월드에 배치, 충돌 형태 설정
## 작성일: 2026-05-21

var ar_manager: Node
var plane_detector: Node3D
var status_label: Label
var mesh_instances: Dictionary = {}  # PlaneID → MeshInstance3D
var static_bodies: Dictionary = {}  # PlaneID → StaticBody3D

# 성능 측정
var mesh_generation_times: Array = []
var mesh_count: int = 0

func _ready() -> void:
	print("[Mesh Generator] _ready() 시작")
	plane_detector = get_parent()
	print("[Mesh Generator] plane_detector: %s" % plane_detector)

	# plane_detector의 부모인 ar_manager를 직접 찾기 (신호 연결 순서 문제 해결)
	ar_manager = plane_detector.get_parent()
	print("[Mesh Generator] ar_manager: %s" % ar_manager)

	# StatusLabel 참조
	status_label = get_node_or_null("../../../CanvasLayer/StatusLabel")
	print("[Mesh Generator] status_label: %s" % status_label)

	if ar_manager:
		print("[Mesh Generator] ar_manager 존재, 신호 확인 중...")
		if ar_manager.has_signal("plane_detected"):
			ar_manager.plane_detected.connect(_on_plane_detected)
			print("[Mesh Generator] ✅ plane_detected 신호 연결 완료")
		else:
			print("[Mesh Generator] ❌ plane_detected 신호 없음!")
	else:
		print("[Mesh Generator] ❌ ar_manager를 찾을 수 없습니다!")

## 평면 감지 → 메시 생성
func _on_plane_detected(plane_data: Dictionary) -> void:
	print("[Mesh Generator] _on_plane_detected 호출됨! ID=%d" % plane_data["id"])
	mesh_count += 1

	# UI 업데이트: 메시 생성 카운트 표시
	if status_label:
		status_label.text = "[메시 생성 중...]\n생성된 평면: %d개" % mesh_count

	var start_time = Time.get_ticks_msec()

	# 테스트: BoxMesh 사용 (메시 생성 로직 검증)
	var vertices = plane_data["vertices"]

	# 정점으로부터 크기 계산
	var min_pos = vertices[0]
	var max_pos = vertices[0]
	for vertex in vertices:
		min_pos = min_pos.min(vertex)
		max_pos = max_pos.max(vertex)

	var size = max_pos - min_pos
	# z가 0인 경우 최소 두께 설정 (평면이 너무 얇아서 안 보임)
	if size.z < 0.01:
		size.z = 0.1

	var mesh = BoxMesh.new()
	mesh.size = size
	print("[Mesh Generator] BoxMesh 생성: size=%.2f x %.2f x %.2f (vertices: %d개)" % [
		mesh.size.x, mesh.size.y, mesh.size.z, vertices.size()
	])

	print("[Mesh Generator] 메시 생성 성공, StaticBody3D 생성 중...")

	# StaticBody3D 생성 (충돌)
	var static_body = _create_static_body(mesh, plane_data["center"])

	# 저장
	mesh_instances[plane_data["id"]] = static_body.get_node("MeshInstance3D")
	static_bodies[plane_data["id"]] = static_body

	add_child(static_body)
	print("[Mesh Generator] ✅ 노드 추가 완료, 위치: %s" % static_body.position)

	# 성능 측정
	var elapsed = Time.get_ticks_msec() - start_time
	mesh_generation_times.append(elapsed)

	print("[Mesh Generator] 메시 생성: ID=%d, 시간=%.2fms" % [plane_data["id"], elapsed])

	# UI 업데이트: 완료 메시지
	if status_label:
		status_label.text = "[✅ 메시 생성 완료]\n평면 ID: %d | 개수: %d | 크기: %.1fx%.1fx%.1f" % [
			plane_data["id"], mesh_count, mesh.size.x, mesh.size.y, mesh.size.z
		]

## 꼭짓점 배열 → Mesh 변환
func _create_mesh_from_vertices(vertices: PackedVector3Array) -> Mesh:
	# 최소 정점 수 확인
	if vertices.size() < 3:
		print("[Mesh Generator] ❌ 정점 부족: %d개" % vertices.size())
		return null

	print("[Mesh Generator] 메시 생성 중... 정점 수: %d" % vertices.size())

	# 삼각형 분해 (복잡한 다각형 → 삼각형 목록)
	var triangles = _triangulate_polygon(vertices)
	print("[Mesh Generator] 삼각형 분해 완료: %d개" % (triangles.size() / 3))

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
	print("[Mesh Generator] Mesh.commit() 완료")
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
	print("[Mesh Generator] StaticBody3D 생성 중... 위치: %s" % position)
	var body = StaticBody3D.new()
	body.position = position

	# MeshInstance3D (시각화)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.name = "MeshInstance3D"
	print("[Mesh Generator] MeshInstance3D 생성 완료")

	# 반투명 재료 (오버레이 효과)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 1.0, 0.8)  # 파란색, 더 진한 투명도
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # lighting 없이 렌더링
	mesh_instance.material_override = material
	print("[Mesh Generator] 재료 적용 완료 (unshaded)")

	body.add_child(mesh_instance)

	# CollisionShape3D (물리)
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh.create_trimesh_shape()
	body.add_child(collision_shape)

	print("[Mesh Generator] StaticBody3D 생성 완료")
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
