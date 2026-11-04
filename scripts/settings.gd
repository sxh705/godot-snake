extends Node
## 全局设置（自动加载，节点名 Settings）
## 音量与光标设置，持久化到 user://settings.cfg

const SAVE_PATH := "user://settings.cfg"
const CURSOR_TEXTURE := "res://assets/cursor_crosshair.svg"

## 主音量 0-100
var volume: float = 80.0
## 0=系统默认 1=隐藏光标 2=准星光标
var cursor_mode: int = 0


func _ready() -> void:
	load_settings()
	_apply_volume()
	_apply_cursor()


func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 100.0)
	_apply_volume()
	save_settings()


func set_cursor_mode(mode: int) -> void:
	cursor_mode = clampi(mode, 0, 2)
	_apply_cursor()
	save_settings()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume / 100.0) if volume > 0.01 else -80.0)


func _apply_cursor() -> void:
	# 触屏设备没有鼠标光标概念
	if OS.has_feature("mobile") or OS.has_feature("web"):
		return
	Input.set_custom_mouse_cursor(null)
	match cursor_mode:
		1:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		2:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			var tex := load(CURSOR_TEXTURE) as Texture2D
			if tex:
				Input.set_custom_mouse_cursor(tex, Input.CURSOR_ARROW, Vector2(16, 16))
		_:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("input", "cursor_mode", cursor_mode)
	cfg.save(SAVE_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	volume = clampf(float(cfg.get_value("audio", "volume", volume)), 0.0, 100.0)
	cursor_mode = clampi(int(cfg.get_value("input", "cursor_mode", cursor_mode)), 0, 2)
