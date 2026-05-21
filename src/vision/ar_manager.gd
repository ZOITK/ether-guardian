extends Node

## AR 매니저: Android/iOS 카메라 통합 관리
## 작성일: 2026-05-21

signal ar_session_initialized
signal ar_session_failed(error: String)

@onready var display: TextureRect = $"../CameraFeed"
@onready var status_label: Label = $"../StatusLabel"

var current_feed = null
var ar_active: bool = false

func _ready() -> void:
	platform_name = OS.get_name()
	print("[AR Manager] 플랫폼: %s" % platform_name)

	# 권한 요청
	_request_permissions()

	# 카메라 서버 모니터링 활성화
	CameraServer.set_monitoring_feeds(true)
	CameraServer.camera_feeds_updated.connect(_on_camera_feeds_updated)

	# 초기 카메라 목록 로드
	_on_camera_feeds_updated()

## 플랫폼별 권한 요청
func _request_permissions() -> void:
	print("[AR Manager] 권한 요청 중...")

	if platform_name == "Android":
		OS.request_permission("CAMERA")
		OS.request_permission("ACCESS_FINE_LOCATION")
	elif platform_name == "iOS":
		OS.request_permission("CAMERA")
		OS.request_permission("ACCESS_FINE_LOCATION")

	print("[AR Manager] ✅ 권한 요청 완료")

## 카메라 피드 업데이트
func _on_camera_feeds_updated() -> void:
	var feeds = CameraServer.feeds()
	print("[AR Manager] 카메라 피드 수: %d" % feeds.size())

	if feeds.size() > 0:
		current_feed = feeds[0]
		print("[AR Manager] 카메라: %s" % current_feed.get_name())
		_start_camera()
	else:
		print("[AR Manager] ❌ 카메라 없음")
		if status_label:
			status_label.text = "카메라 없음"

## 카메라 시작
func _start_camera() -> void:
	if not current_feed or not display:
		print("[AR Manager] ❌ 카메라 또는 디스플레이 없음")
		return

	print("[AR Manager] 카메라 활성화 중...")

	# CameraTexture 생성 (Y 채널)
	var y_tex = CameraTexture.new()
	y_tex.camera_feed_id = current_feed.get_id()
	y_tex.which_feed = CameraServer.FEED_Y_IMAGE

	# TextureRect에 할당
	display.texture = y_tex

	# 카메라 활성화 (피드의 active 속성 설정)
	current_feed.is_active = true
	ar_active = true

	ar_session_initialized.emit()

	if status_label:
		status_label.text = "✅ 카메라 활성화\nFPS: 0"

	print("[AR Manager] ✅ 카메라 활성화됨")

## 카메라 정지
func stop_camera() -> void:
	if current_feed:
		current_feed.is_active = false
	ar_active = false
	print("[AR Manager] 카메라 정지됨")

## FPS 모니터링
func _process(delta: float) -> void:
	if ar_active and status_label:
		var fps = Engine.get_frames_per_second()
		status_label.text = "✅ 카메라 활성화\nFPS: %.1f" % fps

var platform_name: String = ""
