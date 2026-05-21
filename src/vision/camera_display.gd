extends Node

## 카메라 표시기: 카메라 상태 표시
## 작성일: 2026-05-21

signal camera_feed_started
signal camera_feed_stopped
signal fps_updated(current_fps: float)

var is_running: bool = false
var camera_feed = null
var texture_rect: TextureRect = null
var status_label: Label = null
var fps_counter: int = 0
var fps_timer: float = 0.0
var current_fps: float = 0.0

func _ready() -> void:
	_setup()

func _setup() -> void:
	var root = get_tree().root.get_child(0)
	texture_rect = root.get_node_or_null("CameraFeed")

	if texture_rect:
		texture_rect.self_modulate = Color.GRAY
		print("[Camera Display] ✅ TextureRect 찾음")
	else:
		print("[Camera Display] ❌ TextureRect 없음")
		return

	status_label = Label.new()
	status_label.text = "카메라 초기화 중..."
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.anchor_left = 0.5
	status_label.anchor_top = 0.5
	status_label.offset_left = -150
	status_label.offset_top = -50
	texture_rect.add_child(status_label)

func start_camera_feed() -> bool:
	if is_running:
		return true

	if not texture_rect:
		return false

	print("[Camera Display] 카메라 피드 시작 중...")

	CameraServer.set_monitoring_feeds(true)

	camera_feed = CameraServer.get_feed(0)
	if not camera_feed:
		print("[Camera Display] ❌ 카메라 없음")
		if status_label:
			status_label.text = "카메라 없음"
		return false

	is_running = true
	camera_feed_started.emit()

	if status_label:
		status_label.text = "✅ 카메라 활성화\nFPS: 0"

	print("[Camera Display] ✅ 카메라 활성화됨")
	return true

func stop_camera_feed() -> void:
	if not is_running:
		return

	is_running = false
	camera_feed_stopped.emit()
	print("[Camera Display] 카메라 중지됨")

func _process(delta: float) -> void:
	if not is_running:
		return

	fps_counter += 1
	fps_timer += delta

	if fps_timer >= 1.0:
		current_fps = fps_counter / fps_timer
		fps_counter = 0
		fps_timer = 0.0

		fps_updated.emit(current_fps)

		if status_label:
			status_label.text = "✅ 카메라 활성화\nFPS: %.1f" % current_fps

		if current_fps < 30:
			print("[Camera Display] ⚠️  FPS: %.1f (목표: 30+)" % current_fps)

func get_current_fps() -> float:
	return current_fps

func is_camera_running() -> bool:
	return is_running
