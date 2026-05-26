extends Node

## 카메라 관리: Android/iOS 카메라 피드 통합
## 작성일: 2026-05-21

signal camera_initialized
signal camera_failed(error: String)

@onready var display: TextureRect = $"../CanvasLayer/CameraFeed"
@onready var status_label: Label = $"../CanvasLayer/StatusLabel"

var current_feed = null
var camera_active: bool = false
var y_texture: CameraTexture
var cbcr_texture: CameraTexture

# 카메라 프레임 모니터링
var frame_check_counter: int = 0
var camera_frame_count: int = 0
var time_accumulator: float = 0.0

func _ready() -> void:
	print("[Camera Manager] _ready() 시작")

	# 권한 요청
	_request_permissions()

	# 카메라 피드 모니터링 활성화
	print("[Camera Manager] CameraServer 모니터링 활성화 중...")
	CameraServer.set_monitoring_feeds(true)
	print("[Camera Manager] CameraServer 모니터링 활성화 완료")

	# 신호 중복 연결 방지
	if not CameraServer.camera_feeds_updated.is_connected(_on_camera_feeds_updated):
		CameraServer.camera_feeds_updated.connect(_on_camera_feeds_updated)
		print("[Camera Manager] Signal 연결 완료")

	# 초기 카메라 목록 로드
	print("[Camera Manager] 초기 카메라 목록 로드 중...")
	_on_camera_feeds_updated()
	print("[Camera Manager] _ready() 완료")

## 플랫폼별 권한 요청
func _request_permissions() -> void:
	var platform = OS.get_name()
	print("[Camera Manager] 플랫폼: %s" % platform)

	if platform == "Android":
		print("[Camera Manager] 권한 요청: CAMERA, ACCESS_FINE_LOCATION")
		OS.request_permission("CAMERA")
		OS.request_permission("ACCESS_FINE_LOCATION")
	elif platform == "iOS":
		print("[Camera Manager] 권한 요청: CAMERA, ACCESS_FINE_LOCATION")
		OS.request_permission("CAMERA")
		OS.request_permission("ACCESS_FINE_LOCATION")

## 카메라 피드 업데이트 감지
func _on_camera_feeds_updated() -> void:
	var feeds = CameraServer.feeds()
	print("[Camera Manager] 사용 가능한 카메라: %d개" % feeds.size())

	# 디버그: 카메라 감지 안 되면 원인 파악
	if feeds.size() == 0:
		print("[Camera Manager] ⚠️ 카메라 감지 안 됨!")
		print("[Camera Manager] CameraServer.monitoring_feeds: %s" % CameraServer.is_monitoring_feeds())
		_set_status("⚠️ 카메라 감지 안 됨")
		return

	# 모든 사용 가능한 카메라 정보 출력
	for i in range(feeds.size()):
		var feed = feeds[i]
		print("[Camera Manager]   [%d] %s (ID: %d)" % [i, feed.get_name(), feed.get_id()])

	if feeds.size() > 0:
		# 후면 카메라(BACK) 찾기
		var back_camera = null
		for feed in feeds:
			if "BACK" in feed.get_name():
				back_camera = feed
				break

		# 후면 카메라 없으면 첫 번째 카메라 사용
		if back_camera:
			current_feed = back_camera
			print("[Camera Manager] 후면 카메라 선택: %s (ID: %d)" % [current_feed.get_name(), current_feed.get_id()])
		else:
			current_feed = feeds[0]
			print("[Camera Manager] 첫 번째 카메라 선택: %s (ID: %d)" % [current_feed.get_name(), current_feed.get_id()])

		_start_camera()
	else:
		print("[Camera Manager] ❌ 카메라 없음")
		_set_status("카메라 없음")

## 카메라 시작
func _start_camera() -> void:
	if not current_feed:
		print("[Camera Manager] ❌ 카메라 피드 없음")
		_set_status("카메라 피드 없음")
		return

	if not display:
		print("[Camera Manager] ❌ TextureRect 없음")
		_set_status("디스플레이 없음")
		return

	print("[Camera Manager] 카메라 시작 중...")
	print("[Camera Manager] 카메라 ID: %d" % current_feed.get_id())

	# 카메라 포맷 선택
	var formats = current_feed.get_formats()
	print("[Camera Manager] 가능한 포맷 수: %d" % formats.size())

	var best_format_idx = 0

	# Android/macOS 호환: 포맷 정보가 있으면 최적 선택, 없으면 기본값 사용
	if formats.size() > 0:
		var target_width = 1920
		var target_height = 1080
		var best_diff = 999999

		# 목표 해상도에 가장 가까운 포맷 찾기
		for i in range(formats.size()):
			var fmt = formats[i]
			var w = fmt["width"]
			var h = fmt["height"]
			var fps = fmt.get("fps", 0)
			var diff = abs(w - target_width) + abs(h - target_height)

			print("[Camera Manager] [%d] %dx%d @ %d FPS" % [i, w, h, fps])

			# 1920x1080 또는 1280x720이 최적
			if (w <= 1920 and h <= 1080) and diff < best_diff:
				best_diff = diff
				best_format_idx = i

		var selected_fmt = formats[best_format_idx]
		print("[Camera Manager] 선택 포맷: %dx%d (인덱스: %d)" % [selected_fmt["width"], selected_fmt["height"], best_format_idx])

	else:
		print("[Camera Manager] ⚠️ 포맷 정보 없음 (macOS) - 기본값 사용")

	current_feed.set_format(best_format_idx, {})

	# Y와 CBCR 텍스처 생성
	if not y_texture:
		y_texture = CameraTexture.new()
		y_texture.camera_feed_id = current_feed.get_id()
		y_texture.which_feed = CameraServer.FEED_Y_IMAGE
		print("[Camera Manager] Y 텍스처 생성")

	if not cbcr_texture:
		cbcr_texture = CameraTexture.new()
		cbcr_texture.camera_feed_id = current_feed.get_id()
		cbcr_texture.which_feed = CameraServer.FEED_CBCR_IMAGE
		print("[Camera Manager] CBCR 텍스처 생성")

	# 모든 플랫폼: YUV → RGB Shader (CBCR이 없으면 기본값 사용)
	var yuv_shader = load("res://src/vision/yuv_to_rgb.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = yuv_shader
	mat.set_shader_parameter("y_texture", y_texture)
	mat.set_shader_parameter("cbcr_texture", cbcr_texture)
	display.material = mat
	display.texture = y_texture
	print("[Camera Manager] YUV Shader 적용")
	print("[Camera Manager] TextureRect 텍스처 할당 완료")

	# 카메라 활성화
	current_feed.feed_is_active = true
	camera_active = true
	print("[Camera Manager] feed_is_active 설정: true")

	# 초기 메모리 상태 기록
	var init_memory = OS.get_static_memory_usage() / 1024 / 1024
	print("[Camera Manager] 초기 메모리: %d MB" % init_memory)

	_set_status("✅ 카메라 활성화")
	print("[Camera Manager] ✅ 카메라 활성화 완료")
	camera_initialized.emit()

## 상태 레이블 업데이트
func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text

## 카메라 정지
func stop_camera() -> void:
	if current_feed:
		current_feed.feed_is_active = false
	camera_active = false
	print("[Camera Manager] 카메라 정지")

## 노드 삭제 시 리소스 정리
func _exit_tree() -> void:
	stop_camera()
	if CameraServer.camera_feeds_updated.is_connected(_on_camera_feeds_updated):
		CameraServer.camera_feeds_updated.disconnect(_on_camera_feeds_updated)
	print("[Camera Manager] 리소스 정리 완료")

## FPS 모니터링 (화면 FPS + 카메라 FPS + 메모리)
func _process(delta: float) -> void:
	if camera_active and status_label:
		var screen_fps = Engine.get_frames_per_second()
		var memory_mb = OS.get_static_memory_usage() / 1024 / 1024

		# 매 프레임 카메라 프레임 카운팅
		camera_frame_count += 1
		time_accumulator += delta

		# 1초마다 한번 업데이트
		if time_accumulator >= 1.0:
			var camera_fps = camera_frame_count
			var status_text = "✅ 카메라 활성화\n화면 FPS: %.1f | 카메라: %d\n메모리: %d MB" % [screen_fps, camera_fps, memory_mb]

			if status_label:
				status_label.text = status_text
				# 폰트 크기 강제 설정 (GDScript)
				status_label.add_theme_font_size_override("font_size", 80)

			print("[Camera Manager] 화면 FPS: %.1f | 카메라: %d FPS | 메모리: %d MB" % [screen_fps, camera_fps, memory_mb])

			camera_frame_count = 0
			time_accumulator = 0.0
