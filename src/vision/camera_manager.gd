extends Node

## 카메라 관리: Android/iOS 카메라 피드 통합
## 작성일: 2026-05-21

signal camera_initialized
signal camera_failed(error: String)

@onready var display: TextureRect = $"../CameraFeed"
@onready var status_label: Label = $"../StatusLabel"

var current_feed = null
var camera_active: bool = false
var y_texture: CameraTexture
var cbcr_texture: CameraTexture

func _ready() -> void:
	# 권한 요청
	_request_permissions()

	# 카메라 피드 모니터링 활성화
	CameraServer.set_monitoring_feeds(true)
	CameraServer.camera_feeds_updated.connect(_on_camera_feeds_updated)

	# 초기 카메라 목록 로드
	_on_camera_feeds_updated()

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

	# 카메라 포맷 설정
	var formats = current_feed.get_formats()
	print("[Camera Manager] 가능한 포맷 수: %d" % formats.size())

	if formats.size() > 0:
		var fmt = formats[0]
		print("[Camera Manager] 포맷 설정: %dx%d (FPS: %d)" % [fmt["width"], fmt["height"], fmt.get("fps", 0)])
		current_feed.set_format(0, {"output": "copy"})

	# Y와 CBCR 텍스처 생성
	y_texture = CameraTexture.new()
	y_texture.camera_feed_id = current_feed.get_id()
	y_texture.which_feed = CameraServer.FEED_Y_IMAGE
	print("[Camera Manager] Y 텍스처 생성: feed_id=%d" % y_texture.camera_feed_id)

	cbcr_texture = CameraTexture.new()
	cbcr_texture.camera_feed_id = current_feed.get_id()
	cbcr_texture.which_feed = CameraServer.FEED_CBCR_IMAGE
	print("[Camera Manager] CBCR 텍스처 생성: feed_id=%d" % cbcr_texture.camera_feed_id)

	# 셰이더 재료에 텍스처 전달
	var mat = display.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("y_texture", y_texture)
		mat.set_shader_parameter("cbcr_texture", cbcr_texture)
		print("[Camera Manager] 셰이더 매개변수 설정 완료")
	else:
		print("[Camera Manager] ⚠️ ShaderMaterial 없음")
		return

	# TextureRect의 메인 텍스처로 Y 텍스처 설정
	display.texture = y_texture
	print("[Camera Manager] TextureRect 텍스처 할당 완료")

	# 카메라 활성화
	current_feed.feed_is_active = true
	camera_active = true
	print("[Camera Manager] feed_is_active 설정: true")

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

## FPS 모니터링
func _process(delta: float) -> void:
	if camera_active and status_label:
		var fps = Engine.get_frames_per_second()
		status_label.text = "✅ 카메라 활성화\nFPS: %.1f" % fps
