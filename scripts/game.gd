extends Control
## 贪吃蛇主玩法：网格移动、吃食物变长加速、撞墙撞身结束
## 操作：方向键 / WASD，触屏滑动；R 重开，Esc 返回主页

const CELL := 40
const COLS := 24
const ROWS := 14
const BASE_TICK := 0.15
const MIN_TICK := 0.06
const SPEEDUP := 0.004
const FOOD_SCORE := 10
const BEST_PATH := "user://snake_best.cfg"

const COLOR_BOARD := Color(0.11, 0.14, 0.16)
const COLOR_GRID := Color(1.0, 1.0, 1.0, 0.04)
const COLOR_SNAKE := Color(0.29, 0.8, 0.44)
const COLOR_HEAD := Color(0.5, 0.95, 0.6)
const COLOR_FOOD := Color(0.9, 0.32, 0.25)

var snake: Array[Vector2i] = []
var dir := Vector2i.RIGHT
var queued_dir := Vector2i.RIGHT
var food := Vector2i(12, 7)
var score := 0
var best := 0
var tick_time := BASE_TICK
var acc := 0.0
var alive := false
var _swipe_start := Vector2.ZERO

@onready var board: Control = $Center/Board
@onready var score_label: Label = $Score
@onready var game_over: Control = $GameOver
@onready var final_label: Label = $GameOver/Center/Panel/Margin/VBox/FinalScore


func _ready() -> void:
	board.draw.connect(_draw_board)
	$GameOver/Center/Panel/Margin/VBox/RestartButton.pressed.connect(start_game)
	$GameOver/Center/Panel/Margin/VBox/BackButton.pressed.connect(_go_start)
	$BackButton.pressed.connect(_go_start)
	_load_best()
	start_game()
	# 触屏方向键：只在支持触屏的设备上显示（滑动依旧可用）
	var pad: Control = $TouchPad
	pad.visible = DisplayServer.is_touchscreen_available()
	for pair in [["BtnUp", Vector2i.UP], ["BtnLeft", Vector2i.LEFT], ["BtnRight", Vector2i.RIGHT], ["BtnDown", Vector2i.DOWN]]:
		var btn: Button = pad.get_node(pair[0])
		btn.button_down.connect(_turn.bind(pair[1]))


func _process(delta: float) -> void:
	if not alive:
		return
	acc += delta
	if acc >= tick_time:
		acc = 0.0
		_tick()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_UP, KEY_W:
				_turn(Vector2i.UP)
			KEY_DOWN, KEY_S:
				_turn(Vector2i.DOWN)
			KEY_LEFT, KEY_A:
				_turn(Vector2i.LEFT)
			KEY_RIGHT, KEY_D:
				_turn(Vector2i.RIGHT)
			KEY_R:
				start_game()
			KEY_ESCAPE:
				_go_start()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start = event.position
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		var d: Vector2 = drag.position - _swipe_start
		if d.length() >= 48.0:
			if absf(d.x) > absf(d.y):
				_turn(Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT)
			else:
				_turn(Vector2i.DOWN if d.y > 0 else Vector2i.UP)
			_swipe_start = event.position


func _turn(d: Vector2i) -> void:
	# 不允许直接掉头；一帧只接受一次转向，存在 queued_dir 待下一个 tick 生效
	if not alive or d == -dir:
		return
	queued_dir = d


func start_game() -> void:
	snake = [Vector2i(8, 7), Vector2i(7, 7), Vector2i(6, 7)]
	dir = Vector2i.RIGHT
	queued_dir = dir
	score = 0
	tick_time = BASE_TICK
	acc = 0.0
	alive = true
	game_over.visible = false
	_spawn_food()
	_update_score()
	board.queue_redraw()


func _tick() -> void:
	dir = queued_dir
	var head := snake[0] + dir
	# 撞墙
	if head.x < 0 or head.y < 0 or head.x >= COLS or head.y >= ROWS:
		_die()
		return
	# 撞自己（尾巴尖这一步会让开，不检查）
	for i in snake.size() - 1:
		if snake[i] == head:
			_die()
			return
	snake.push_front(head)
	if head == food:
		score += FOOD_SCORE
		tick_time = maxf(MIN_TICK, tick_time - SPEEDUP)
		_spawn_food()
		_update_score()
	else:
		snake.pop_back()
	board.queue_redraw()


func _die() -> void:
	alive = false
	if score > best:
		best = score
		_save_best()
	final_label.text = "本局 %d · 最佳 %d" % [score, best]
	game_over.visible = true
	board.queue_redraw()


func _spawn_food() -> void:
	var free: Array[Vector2i] = []
	for x in COLS:
		for y in ROWS:
			var c := Vector2i(x, y)
			if not snake.has(c):
				free.append(c)
	if free.is_empty():
		return  # 蛇占满全场，胜利局面，不再生成
	food = free.pick_random()


func _update_score() -> void:
	score_label.text = "分数 %d   ·   最佳 %d" % [score, best]


func _draw_board() -> void:
	var size := board.size
	board.draw_rect(Rect2(Vector2.ZERO, size), COLOR_BOARD)
	# 网格线
	for x in range(1, COLS):
		var gx := float(x * CELL)
		board.draw_line(Vector2(gx, 0), Vector2(gx, size.y), COLOR_GRID, 1.0)
	for y in range(1, ROWS):
		var gy := float(y * CELL)
		board.draw_line(Vector2(0, gy), Vector2(size.x, gy), COLOR_GRID, 1.0)
	# 食物
	var fc := Vector2(food.x * CELL + CELL / 2.0, food.y * CELL + CELL / 2.0)
	board.draw_circle(fc, CELL * 0.32, COLOR_FOOD)
	# 蛇身
	for i in snake.size():
		var r := Rect2(Vector2(snake[i]) * CELL + Vector2(2, 2), Vector2(CELL - 4, CELL - 4))
		board.draw_rect(r, COLOR_HEAD if i == 0 else COLOR_SNAKE)


func _go_start() -> void:
	get_tree().change_scene_to_file("res://scenes/start.tscn")


func _load_best() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(BEST_PATH) == OK:
		best = int(cfg.get_value("score", "best", 0))


func _save_best() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", best)
	cfg.save(BEST_PATH)
