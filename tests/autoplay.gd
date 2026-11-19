extends SceneTree
## Headless smoke test: godot --headless --path . -s tests/autoplay.gd
## Plays through all three levels by teleporting Oleg, and fails on stuck states.

var game
var t := 0.0
var phase := 0
var item_i := 0
var wait := 0.0

func _initialize() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)

func _process(delta: float) -> bool:
	t += delta
	if t > 400.0:
		print("FAIL: timeout in phase ", phase, " state=", game.state, " li=", game.li, " built=", game.built)
		quit(1); return true
	wait -= delta
	if wait > 0:
		return false
	match phase:
		0:
			game.start_game(); phase = 1; wait = 1.5
		1:
			if game.state == "intro":
				game.end_cutscene()
			if game.state == "play":
				phase = 2; item_i = 0; print("level ", game.li, " items ", game.items.size(), " pieces ", game.pieces.size())
		2:
			game.P.inv = 999.0
			if item_i < game.items.size():
				var it = game.items[item_i]; game.P.x = it.x; game.P.z = it.z; item_i += 1; wait = 0.2
			else:
				game.P.x = 0.0; game.P.z = -15.0; phase = 3
		3:
			game.P.inv = 999.0
			if game.state == "levelDone":
				print("  level ", game.li, " done, built ", game.built, "/", game.need)
				game.next_level(); phase = 1; wait = 1.5
			elif game.state == "won":
				print("  finale reached, built ", game.built, "/", game.need); phase = 4; wait = 7.0
		4:
			print("win card open: ", game.hud.card_open("win"))
			quit(0 if game.hud.card_open("win") else 1); return true
	return false
