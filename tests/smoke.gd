extends Node
## 无头自检：验证开局强化、每 5 个食物触发强化、护盾与穿墙
## 运行：godot --headless --path . tests/smoke.tscn

var game
var fails: Array[String] = []


func _ready() -> void:
	var ps: PackedScene = load("res://scenes/game.tscn")
	game = ps.instantiate()
	add_child(game)

	_check(game.awaiting_choice, "开局应等待选择强化")
	_check(game.upgrade_panel.visible, "开局强化面板应显示")
	_check(game._options.size() == 3, "应提供 3 个强化选项")

	# 选定第一项后应开始移动
	game._on_option(0)
	_check(not game.awaiting_choice, "选择后应解除等待")
	_check(game.upgrade_panel.visible == false, "选择后面板应隐藏")
	_check(game.alive, "选择后游戏应处于运行态")

	# 强行吃掉 5 个食物，第 5 个应弹出强化
	game.alive = false  # 停掉 _process，只手动推进
	for i in 5:
		game.food = game.snake[0] + game.dir
		game._tick()
	_check(game.eaten == 5, "应吃到 5 个食物，实际 %d" % game.eaten)
	_check(game.score > 0, "分数应大于 0，实际 %d" % game.score)
	_check(game.awaiting_choice, "第 5 个食物后应触发强化")
	_check(game.snake.size() == 8, "吃 5 个后长度应为 8，实际 %d" % game.snake.size())

	# 穿墙：贴右墙后向右走，应从左侧穿出
	game._on_option(0)
	game.alive = false
	game.levels.wrap = 1
	game.levels.shield = 0
	game.snake.assign([Vector2i(game.COLS - 1, 5), Vector2i(game.COLS - 2, 5)])
	game.dir = Vector2i.RIGHT
	game.queued_dir = Vector2i.RIGHT
	game.food = Vector2i(0, 0)
	game._tick()
	_check(game.snake[0] == Vector2i(0, 5), "穿墙后蛇头应在左侧，实际 %s" % str(game.snake[0]))

	# 护盾：撞墙应抵消而非结束
	game.levels.wrap = 0
	game.levels.shield = 1
	game.snake.assign([Vector2i(game.COLS - 1, 6), Vector2i(game.COLS - 2, 6)])
	game.dir = Vector2i.RIGHT
	game.queued_dir = Vector2i.RIGHT
	game.alive = true
	game._tick()
	_check(game.alive, "有护盾时撞墙不应结束")
	_check(game.levels.shield == 0, "护盾应被消耗")
	_check(game.stun > 0.0, "护盾生效后应有停顿")

	# 无护盾再撞一次应结束
	game.stun = 0.0
	game._tick()
	_check(not game.alive, "无护盾撞墙应结束游戏")
	_check(game.game_over.visible, "结束后应显示结束面板")

	if fails.is_empty():
		print("SMOKE PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			print("SMOKE FAIL: ", f)
		get_tree().quit(1)


func _check(cond: bool, msg: String) -> void:
	if not cond:
		fails.append(msg)
