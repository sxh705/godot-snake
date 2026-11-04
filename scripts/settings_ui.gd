extends Control
## 设置页：音量滑条 + 光标模式

@onready var volume_slider: HSlider = $Center/Panel/Margin/VBox/Grid/VolumeSlider
@onready var cursor_option: OptionButton = $Center/Panel/Margin/VBox/Grid/CursorOption


func _ready() -> void:
	cursor_option.add_item("系统默认", 0)
	cursor_option.add_item("隐藏光标", 1)
	cursor_option.add_item("准星光标", 2)

	volume_slider.value = Settings.volume
	cursor_option.select(cursor_option.get_item_index(Settings.cursor_mode))

	# 触屏设备没有鼠标光标，禁用该项
	if OS.has_feature("mobile") or OS.has_feature("web"):
		cursor_option.disabled = true

	volume_slider.value_changed.connect(_on_volume_changed)
	cursor_option.item_selected.connect(_on_cursor_selected)
	$Center/Panel/Margin/VBox/BackButton.pressed.connect(_on_back_pressed)
	$Center/Panel/Margin/VBox/BackButton.grab_focus()


func _on_volume_changed(v: float) -> void:
	Settings.set_volume(v)


func _on_cursor_selected(index: int) -> void:
	Settings.set_cursor_mode(cursor_option.get_item_id(index))


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start.tscn")
