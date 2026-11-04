extends Control
## 贪吃蛇主玩法
## 开局选一次强化，之后每吃 5 个食物再选一次。
## 操作：方向键 / WASD / 触屏方向键 / 滑动；R 重开，Esc 返回主页

const CELL := 40
const COLS := 24
const ROWS := 14
const BASE_TICK := 0.16
const MIN_TICK := 0.05
const FOOD_SCORE := 10
const UPGRADE_EVERY := 5
const BEST_PATH := "user://snake_best.cfg"

## 强化池：max 为可叠加层数，desc 为界面上的一行说明
const PERKS := {
	"shield": {"name": "护盾", "max": 3, "desc": "抵挡一次致命撞击，抵消后短暂停顿供你转向"},
	"wrap": {"name": "穿墙", "max": 1, "desc": "撞墙时从对面穿出"},
	"score": {"name": "双倍分", "max": 3, "desc": "每个食物多 10 分"},
	"speed": {"name": "疾行", "max": 3, "desc": "移速提升，每个食物额外 +5 分"},
	"slow": {"name": "缓行", "max": 2, "desc": "移速下降，操作更从容"},
	"bonus": {"name": "分数 +50", "max": 99, "desc": "直接加 50 分，不占强化位"},
}

const COLOR_BOARD := Color(0.11, 0.14, 0.16)
const COLOR_GRID := Color(1.0, 1.0, 1.0, 0.04)
const COLOR_SNAKE := Color(0.29, 0.8, 0.44)
const COLOR_HEAD := Color(0.5, 0.95, 0.6)
const COLOR_FOOD := Color(0.9, 0.32, 0.25)
const COLOR_SHIELD := Color(0.45, 0.72, 0.98)

var snake: Array[Vector2i] = []
var dir := Vector2i.RIGHT
var queued_dir := Vector2i.RIGHT
var food := Vector2i(12, 7)
var score := 0
var best := 0
var eaten := 0
var tick_time := BASE_TICK
var acc := 0.0
var stun := 0.0
var alive := false
var awaiting_choice := false
var _swipe_start := Vector2.ZERO
var _options: Array[String] = []

var levels := {"shield": 0, "wrap": 0, "score": 0, "speed": 0, "slow": 0, "bonus": 0}

@onready var board: Control = $Center/Board
@onready var score_label: Label = $Score
@onready var perk_label: Label = $PerkLabel
@onready var toast_label: Label = $Toast
@onready var game_over: Control = $GameOver
@onready var final_label: Label = $GameOver/Center/Panel/Margin/VBox/FinalScore
@onready var upgrade_panel: Control = $UpgradePanel
@onready var upgrade_title: Label = $UpgradePanel/Center/Panel/Margin/VBox/Title
@onready var upgrade_sub: Label = $UpgradePanel/Center/Panel/Margin/VBox/Subtitle
@onready var options_box: VBoxContainer = $UpgradePanel/Center/Panel/Margin/VBox/Options


func _ready() -> void:
	board.draw.connect(_draw_board)
	$GameOver/Center/Panel/Margin/VBox/RestartButton.pressed.connect(start_game)
	$GameOver/Center/Panel/Margin/VBox/BackButton.pressed.connect(_go_start)
	$BackButton.pressed.connect(_go_start)

	var pad: Control = $TouchPad
	pad.visible = DisplayServer.is_touchscreen_available()
	for pair in [["BtnUp", Vector2i.UP], ["BtnLeft", Vector2i.LEFT], ["BtnRight", Vector2i.RIGHT], ["BtnDown", Vector2i.DOWN]]:
		var btn: Button = pad.get_node(pair[0])
		btn.button_down.connect(_turn.bind(pair[1]))

	for i in options_box.get_child_count():
		var b := options_box.get_child(i) as Button
		b.pressed.connect(_on_option.bind(i))

	_load_best()
	start_game()


func _process(delta: float) -> void:
	if toast_label.visible:
		toast_label.modulate.a = maxf(0.0, toast_label.modulate.a - delta * 1.2)
		if toast_label.modulate.a <= 0.01:
			toast_label.visible = false
	if not alive or awaiting_choice:
		return
	if stun > 0.0:
		stun -= delta
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
				if not awaiting_choice:
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
			_swipe_start = drag.position


func _turn(d: Vector2i) -> void:
	# 不允许直接掉头；转向排队到下一个 tick 生效
	if not alive or awaiting_choice or d == -dir:
		return
	queued_dir = d


func start_game() -> void:
	snake = [Vector2i(8, 7), Vector2i(7, 7), Vector2i(6, 7)]
	dir = Vector2i.RIGHT
	queued_dir = dir
	score = 0
	eaten = 0
	stun = 0.0
	acc = 0.0
	levels = {"shield": 0, "wrap": 0, "score": 0, "speed": 0, "slow": 0, "bonus": 0}
	tick_time = _compute_tick()
	alive = false
	game_over.visible = false
	_spawn_food()
	_update_hud()
	board.queue_redraw()
	_offer_upgrades(true)


func _compute_tick() -> float:
	var t := BASE_TICK
	t *= pow(0.975, float(eaten))  # 吃越多自然越快
	t *= pow(0.9, float(levels.speed))  # 疾行
	t *= pow(1.12, float(levels.slow))  # 缓行
	return maxf(MIN_TICK, t)


func _food_value() -> int:
	return FOOD_SCORE + levels.score * 10 + levels.speed * 5


func _tick() -> void:
	dir = queued_dir
	var head := snake[0] + dir

	# 撞墙
	if head.x < 0 or head.y < 0 or head.x >= COLS or head.y >= ROWS:
		if levels.wrap > 0:
			head = Vector2i(posmod(head.x, COLS), posmod(head.y, ROWS))
		else:
			_hit()
			return

	# 撞自己（尾巴尖这一步会让开，不检查）
	for i in snake.size() - 1:
		if snake[i] == head:
			_hit()
			return

	snake.push_front(head)
	if head == food:
		var gain := _food_value()
		score += gain
		eaten += 1
		tick_time = _compute_tick()
		_spawn_food()
		_update_hud()
		if eaten % UPGRADE_EVERY == 0:
			awaiting_choice = true
			board.queue_redraw()
			_offer_upgrades(false)
			return
	else:
		snake.pop_back()
	board.queue_redraw()


## 致命撞击：有护盾则抵消并停顿，让玩家转向
func _hit() -> void:
	if levels.shield > 0:
		levels.shield -= 1
		stun = 0.8
		acc = 0.0
		_show_toast("护盾抵消，快转向！")
		_update_hud()
		board.queue_redraw()
		return
	_die()


func _die() -> void:
	alive = false
	if score > best:
		best = score
		_save_best()
	final_label.text = "本局 %d · 吃到 %d 个 · 最佳 %d" % [score, eaten, best]
	game_over.visible = true
	board.queue_redraw()


## 抽 3 个可选强化，maxed 的自动排除；不足则用加分补齐
func _offer_upgrades(fresh: bool) -> void:
	awaiting_choice = true
	var pool: Array[String] = []
	for k in PERKS.keys():
		if levels[k] < PERKS[k]["max"]:
			pool.append(k)
	pool.shuffle()
	_options.clear()
	for i in 3:
		_options.append(pool[i] if i < pool.size() else "bonus")

	for i in 3:
		var key := _options[i]
		var info: Dictionary = PERKS[key]
		var btn := options_box.get_child(i) as Button
		if key == "bonus":
			btn.text = "%s\n%s" % [info["name"], info["desc"]]
		else:
			var next_lv: int = levels[key] + 1
			btn.text = "%s  Lv.%d → Lv.%d\n%s" % [info["name"], levels[key], next_lv, info["desc"]]

	upgrade_title.text = "开局强化" if fresh else "第 %d 个食物 · 强化" % eaten
	upgrade_sub.text = "开局先选一项，之后每吃 %d 个食物再选一次" % UPGRADE_EVERY
	upgrade_panel.visible = true
	(options_box.get_child(0) as Button).grab_focus()


func _on_option(index: int) -> void:
	if not awaiting_choice or index >= _options.size():
		return
	_apply_perk(_options[index])
	awaiting_choice = false
	upgrade_panel.visible = false
	alive = true
	acc = 0.0
	tick_time = _compute_tick()
	_update_hud()
	board.queue_redraw()


func _apply_perk(key: String) -> void:
	if key == "bonus":
		score += 50
	else:
		levels[key] += 1
	if key == "shield" or key == "wrap":
		_show_toast("%s 已生效" % PERKS[key]["name"])


func _spawn_food() -> void:
	var free: Array[Vector2i] = []
	for x in COLS:
		for y in ROWS:
			var c := Vector2i(x, y)
			if not snake.has(c):
				free.append(c)
	if free.is_empty():
		return
	food = free.pick_random()


func _update_hud() -> void:
	score_label.text = "分数 %d   ·   已吃 %d   ·   最佳 %d" % [score, eaten, best]
	var parts: Array[String] = []
	for k in ["shield", "wrap", "score", "speed", "slow"]:
		if levels[k] > 0:
			parts.append("%s×%d" % [PERKS[k]["name"], levels[k]] if PERKS[k]["max"] > 1 else PERKS[k]["name"])
	perk_label.text = "强化：" + ("无" if parts.is_empty() else "  ".join(PackedStringArray(parts)))


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.visible = true


func _draw_board() -> void:
	var size := board.size
	board.draw_rect(Rect2(Vector2.ZERO, size), COLOR_BOARD)
	for x in range(1, COLS):
		var gx := float(x * CELL)
		board.draw_line(Vector2(gx, 0), Vector2(gx, size.y), COLOR_GRID, 1.0)
	for y in range(1, ROWS):
		var gy := float(y * CELL)
		board.draw_line(Vector2(0, gy), Vector2(size.x, gy), COLOR_GRID, 1.0)
	var fc := Vector2(food.x * CELL + CELL / 2.0, food.y * CELL + CELL / 2.0)
	board.draw_circle(fc, CELL * 0.32, COLOR_FOOD)
	for i in snake.size():
		var r := Rect2(Vector2(snake[i]) * CELL + Vector2(2, 2), Vector2(CELL - 4, CELL - 4))
		board.draw_rect(r, COLOR_HEAD if i == 0 else COLOR_SNAKE)
	# 有护盾时给蛇头描一圈
	if levels.shield > 0 and not snake.is_empty():
		var hr := Rect2(Vector2(snake[0]) * CELL + Vector2(2, 2), Vector2(CELL - 4, CELL - 4))
		board.draw_rect(hr, COLOR_SHIELD, false, 3.0)


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
