extends Control
## 开始页：游戏名称 + 开始 / 设置按钮


func _ready() -> void:
	$Center/VBox/StartButton.pressed.connect(_on_start_pressed)
	$Center/VBox/SettingsButton.pressed.connect(_on_settings_pressed)
	$Center/VBox/StartButton.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
