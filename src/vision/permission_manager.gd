extends Node

## 권한 관리자: Android/iOS 카메라 권한 요청 및 상태 추적
## 역할: 플랫폼별 런타임 권한 요청, 권한 거부 시 재요청 유도
## 작성일: 2026-05-21

# 신호
signal permission_granted(permission: String)
signal permission_denied(permission: String)
signal permission_request_complete(granted: bool)

# 권한 상태
enum PermissionState { UNKNOWN, GRANTED, DENIED, PERMANENTLY_DENIED }

# 권한 타입 (플랫폼별)
var camera_permission: String = ""
var location_permission: String = ""
var permission_states: Dictionary = {}

func _ready() -> void:
	platform_name = OS.get_name()
	_initialize_permissions()

## 플랫폼별 권한 초기화
func _initialize_permissions() -> void:
	if platform_name == "Android":
		camera_permission = "android.permission.CAMERA"
		location_permission = "android.permission.ACCESS_FINE_LOCATION"
	elif platform_name == "iOS":
		camera_permission = "camera"
		location_permission = "location"

## 카메라 권한 요청
func request_camera_permission() -> bool:
	print("[Permission Manager] 카메라 권한 요청 중... (플랫폼: %s)" % OS.get_name())

	if OS.get_name() == "Android":
		return _request_android_permission(camera_permission)
	elif OS.get_name() == "iOS":
		return _request_ios_permission(camera_permission)
	else:
		print("[Permission Manager] 지원되지 않는 플랫폼: %s" % OS.get_name())
		return false

## 위치 권한 요청 (영토 시스템용)
func request_location_permission() -> bool:
	print("[Permission Manager] 위치 권한 요청 중... (플랫폼: %s)" % OS.get_name())

	if OS.get_name() == "Android":
		return _request_android_permission(location_permission)
	elif OS.get_name() == "iOS":
		return _request_ios_permission(location_permission)
	else:
		print("[Permission Manager] 지원되지 않는 플랫폼: %s" % OS.get_name())
		return false

## Android 권한 요청 (런타임 권한 - API 23+)
func _request_android_permission(permission: String) -> bool:
	# OS.request_permission() API (Godot 4.6+)
	# 반환값: 권한 승인 여부 (true = 승인, false = 거부)

	if not OS.has_permission(permission):
		var granted = OS.request_permission(permission)

		if granted:
			permission_states[permission] = PermissionState.GRANTED
			permission_granted.emit(permission)
			print("[Permission Manager] ✅ %s 권한 승인됨" % permission)
		else:
			permission_states[permission] = PermissionState.DENIED
			permission_denied.emit(permission)
			print("[Permission Manager] ❌ %s 권한 거부됨" % permission)

		permission_request_complete.emit(granted)
		return granted
	else:
		# 이미 권한이 있음
		permission_states[permission] = PermissionState.GRANTED
		permission_granted.emit(permission)
		print("[Permission Manager] ✅ %s 권한 이미 승인됨" % permission)
		permission_request_complete.emit(true)
		return true

## iOS 권한 요청
func _request_ios_permission(permission: String) -> bool:
	# iOS는 Info.plist에 NSCameraUsageDescription 필수
	# OS.request_permission()은 Godot 4.6+에서 지원

	if not OS.has_permission(permission):
		var granted = OS.request_permission(permission)

		if granted:
			permission_states[permission] = PermissionState.GRANTED
			permission_granted.emit(permission)
			print("[Permission Manager] ✅ %s 권한 승인됨" % permission)
		else:
			permission_states[permission] = PermissionState.DENIED
			permission_denied.emit(permission)
			print("[Permission Manager] ❌ %s 권한 거부됨" % permission)

		permission_request_complete.emit(granted)
		return granted
	else:
		permission_states[permission] = PermissionState.GRANTED
		permission_granted.emit(permission)
		print("[Permission Manager] ✅ %s 권한 이미 승인됨" % permission)
		permission_request_complete.emit(true)
		return true

## 권한 상태 확인
func has_permission(permission: String) -> bool:
	return OS.has_permission(permission)

## 권한 상태 조회
func get_permission_state(permission: String) -> PermissionState:
	return permission_states.get(permission, PermissionState.UNKNOWN)

## 모든 필수 권한 확인
func all_permissions_granted() -> bool:
	return has_permission(camera_permission) and has_permission(location_permission)

## 권한 설정 화면으로 이동 (사용자가 수동으로 권한 활성화할 수 있도록)
func open_app_settings() -> void:
	if OS.get_name() == "Android":
		# Android 설정 앱으로 이동
		var intent = JavaClassWrapper.new("android/content/Intent")
		intent.action = "android.settings.APPLICATION_DETAILS_SETTINGS"
		# uri://android.provider.Settings.EXTRA_APP_PACKAGE
		print("[Permission Manager] Android 설정 화면 열기")
	elif OS.get_name() == "iOS":
		# iOS 설정 앱으로 이동
		print("[Permission Manager] iOS 설정 화면 열기 (자동 전환 미지원 - 수동 필요)")
