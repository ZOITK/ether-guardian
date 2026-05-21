extends Node

## 카메라 표시기: CameraServer API를 통한 실시간 카메라 피드
## 역할: 모바일 기기의 카메라 입력을 TextureRect에 출력, FPS 모니터링
## 작성일: 2026-05-21

# 신호
signal camera_feed_started
signal camera_feed_stopped
signal fps_updated(current_fps: float)

# 카메라 상태
enum CameraState { UNINITIALIZED, STARTING, RUNNING, STOPPING, FAILED }

var camera_state: CameraState = CameraState.UNINITIALIZED
var camera_feed: CameraFeed = null
var texture_rect: TextureRect = null

# 성능 모니터링
var fps_counter: int = 0
var fps_timer: float = 0.0
var current_fps: float = 0.0

func _ready() -> void:
	_find_texture_rect()

## TextureRect 찾기 (씬에서 부모 노드를 통해)
func _find_texture_rect() -> void:
	# 루트 노드(Main)에서 CameraFeed TextureRect 찾기
	var root = get_tree().root.get_child(0)
	texture_rect = root.get_node_or_null("CameraFeed")

	if texture_rect == null:
		print("[Camera Display] ❌ CameraFeed TextureRect를 찾을 수 없음")
		camera_state = CameraState.FAILED
		return

	print("[Camera Display] ✅ TextureRect 찾음")

## 카메라 피드 시작
func start_camera_feed() -> bool:
	if camera_state == CameraState.RUNNING:
		print("[Camera Display] 카메라는 이미 실행 중입니다")
		return true

	camera_state = CameraState.STARTING
	print("[Camera Display] 카메라 피드 시작 중...")

	# CameraServer에서 카메라 피드 가져오기
	var cameras = CameraServer.get_feeds()

	if cameras.is_empty():
		print("[Camera Display] ❌ 카메라 피드 없음 - 카메라를 지원하는 기기인지 확인")
		camera_state = CameraState.FAILED
		return false

	# 첫 번째 카메라 피드 사용
	camera_feed = cameras[0]

	if camera_feed == null:
		print("[Camera Display] ❌ 카메라 피드 초기화 실패")
		camera_state = CameraState.FAILED
		return false

	# 카메라 피드를 Texture2D로 변환하여 TextureRect에 할당
	if camera_feed.get_texture() != null:
		texture_rect.texture = camera_feed.get_texture()
		camera_state = CameraState.RUNNING
		camera_feed_started.emit()
		print("[Camera Display] ✅ 카메라 피드 시작됨")
		return true
	else:
		print("[Camera Display] ❌ 카메라 텍스처 초기화 실패")
		camera_state = CameraState.FAILED
		return false

## 카메라 피드 중지
func stop_camera_feed() -> void:
	if camera_state != CameraState.RUNNING:
		return

	camera_state = CameraState.STOPPING
	print("[Camera Display] 카메라 피드 중지 중...")

	if camera_feed != null:
		camera_feed = null

	if texture_rect != null:
		texture_rect.texture = null

	camera_state = CameraState.UNINITIALIZED
	camera_feed_stopped.emit()
	print("[Camera Display] ✅ 카메라 피드 중지됨")

## FPS 모니터링
func _process(delta: float) -> void:
	if camera_state != CameraState.RUNNING:
		return

	# FPS 계산 (1초마다 갱신)
	fps_counter += 1
	fps_timer += delta

	if fps_timer >= 1.0:
		current_fps = fps_counter / fps_timer
		fps_counter = 0
		fps_timer = 0.0

		fps_updated.emit(current_fps)

		# 성능 경고
		if current_fps < 30:
			print("[Camera Display] ⚠️  낮은 FPS: %.1f (목표: 30+ FPS)" % current_fps)
		else:
			print("[Camera Display] 📊 FPS: %.1f" % current_fps)

## 카메라 상태 반환
func is_camera_running() -> bool:
	return camera_state == CameraState.RUNNING

## 현재 FPS 반환
func get_current_fps() -> float:
	return current_fps
