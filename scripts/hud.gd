extends CanvasLayer
## On-screen interface built in code: HUD pills, compass, ДП-5 dosimeter, messages and menu cards.

const RED := Color("#b3261e")
const GOLD := Color("#d9a441")
const CREAM := Color("#efe3c2")

var head_font: SystemFont
var lives_l: Label
var carry_l: Label
var built_l: Label
var lvl_l: Label
var msg_ru: Label
var msg_en: Label
var sub_ru: Label
var sub_en: Label
var skip_l: Label
var arrow: Control
var ctext: Label
var gauge: Control
var reading: Label
var dose_fill: ColorRect
var led: ColorRect
var rad_tint: ColorRect
var hit_tint: ColorRect
var fade_rect: ColorRect
var hud_root: Control
var det_panel: PanelContainer
var cards := {}
var needle := -70.0
var lives_shown := 3
var msg_t := 0.0
var quality_b: Button
var mute_b: Button

signal pressed(id: String)

func _ready() -> void:
	head_font = SystemFont.new()
	head_font.font_names = PackedStringArray(["Russo One", "Arial Black", "Impact", "Helvetica Neue", "Arial"])
	head_font.font_weight = 800
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
	rad_tint = _tint(root, Color(0.35, 1.0, 0.25, 0.0))
	hit_tint = _tint(root, Color(0.8, 0.1, 0.08, 0.0))
	# vignette
	var vig := TextureRect.new(); vig.set_anchors_preset(Control.PRESET_FULL_RECT); vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.texture = Mk.radial(Color(0, 0, 0, 0), Color(0, 0, 0, 0.6), 256); vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; root.add_child(vig)
	hud_root = Control.new(); hud_root.set_anchors_preset(Control.PRESET_FULL_RECT); hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(hud_root)
	# pills
	var row := HBoxContainer.new(); row.position = Vector2(12, 10); row.add_theme_constant_override("separation", 8); hud_root.add_child(row)
	lives_l = _pill(row, "ЖИЗНИ", "3", Color("#e0392b"))
	lives_l.custom_minimum_size = Vector2(60, 26)
	lives_l.draw.connect(_draw_lives)
	lives_l.text = ""
	carry_l = _pill(row, "В РУКАХ", "0", CREAM)
	built_l = _pill(row, "ПОСТРОЕНО", "0/6", CREAM)
	# level name
	lvl_l = _label(hud_root, "", 17, CREAM, true); lvl_l.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); lvl_l.offset_top = -56; lvl_l.offset_bottom = -8
	lvl_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lvl_l.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# compass
	arrow = Control.new(); arrow.size = Vector2(30, 30); arrow.pivot_offset = Vector2(15, 17); arrow.set_anchors_preset(Control.PRESET_CENTER_TOP)
	arrow.position = Vector2(-15, 60); arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud_root.add_child(arrow)
	arrow.draw.connect(func(): arrow.draw_colored_polygon(PackedVector2Array([Vector2(15, 0), Vector2(29, 28), Vector2(15, 21), Vector2(1, 28)]), GOLD))
	ctext = _label(hud_root, "", 15, CREAM, false); ctext.set_anchors_preset(Control.PRESET_CENTER_TOP); ctext.position = Vector2(-300, 94); ctext.size = Vector2(600, 24)
	ctext.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# dosimeter
	det_panel = PanelContainer.new(); det_panel.add_theme_stylebox_override("panel", _box(Color("#5c5b33"), Color("#2b2a18"), 3, 10))
	det_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); det_panel.position = Vector2(-190, -196); det_panel.custom_minimum_size = Vector2(176, 0)
	det_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE; hud_root.add_child(det_panel)
	var dv := VBoxContainer.new(); dv.add_theme_constant_override("separation", 3); det_panel.add_child(dv)
	var dh := HBoxContainer.new(); dv.add_child(dh)
	var dt := _label(dh, "ДП-5 ДОЗИМЕТР", 12, Color("#f1e7b8"), true); dt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	led = ColorRect.new(); led.custom_minimum_size = Vector2(10, 10); led.color = Color("#3a1010"); dh.add_child(led)
	gauge = Control.new(); gauge.custom_minimum_size = Vector2(160, 66); dv.add_child(gauge)
	gauge.draw.connect(_draw_gauge)
	reading = _label(dv, "0.12", 22, Color("#9dff6a"), true); reading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rb := StyleBoxFlat.new(); rb.bg_color = Color("#101a0c"); rb.set_corner_radius_all(4); reading.add_theme_stylebox_override("normal", rb)
	_label(dv, "мкЗв/ч · radiation", 12, Color("#f1e7b8"), false).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bar := ColorRect.new(); bar.custom_minimum_size = Vector2(160, 10); bar.color = Color("#1a1a10"); dv.add_child(bar)
	dose_fill = ColorRect.new(); dose_fill.color = Color("#8aff4a"); dose_fill.size = Vector2(0, 10); bar.add_child(dose_fill)
	_label(dv, "ДОЗА · your dose", 12, Color("#f1e7b8"), false).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# buttons
	mute_b = _small_button(root, "ЗВУК", Vector2(-74, 10)); mute_b.pressed.connect(func(): pressed.emit("mute"))
	quality_b = _small_button(root, "HQ", Vector2(-128, 10)); quality_b.pressed.connect(func(): pressed.emit("quality"))
	# messages
	var mv := VBoxContainer.new(); mv.set_anchors_preset(Control.PRESET_CENTER_TOP); mv.position = Vector2(-520, 150); mv.size = Vector2(1040, 120)
	mv.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(mv)
	msg_ru = _label(mv, "", 42, Color("#e8c35a"), true); msg_ru.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; msg_ru.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_en = _label(mv, "", 22, Color.WHITE, false); msg_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; msg_en.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mv.modulate.a = 0.0; mv.name = "Msg"
	var sv := VBoxContainer.new(); sv.set_anchors_preset(Control.PRESET_CENTER_BOTTOM); sv.position = Vector2(-560, -140); sv.size = Vector2(1120, 90)
	sv.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(sv)
	sub_ru = _label(sv, "", 28, CREAM, true); sub_ru.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_en = _label(sv, "", 19, Color("#cdbf9a"), false); sub_en.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_l = _label(root, "Пробел / click — пропустить (skip)", 14, Color("#cdbf9a"), false)
	skip_l.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); skip_l.position = Vector2(-280, -30); skip_l.visible = false
	# cards
	_menu(root)
	_card(root, "help", "★", "КАК ИГРАТЬ", "How to play",
		"Block No. 4 of the Chernobyl power plant lies in ruins and smoke is still rising from it. Collect building materials, carry them to the construction site and rebuild it until the smoke stops. Watch your radiation detector, falling junk, ceiling traps and patrol guards.\n\nWASD / arrows: walk   ·   Shift: run   ·   Q E / drag mouse: camera\nM: sound   ·   G: graphics HQ / LQ   ·   P: photo mode\nGreen glow = radiation   ·   Red stars = extra lives",
		"НАЗАД · BACK", "back")
	_card(root, "done", "★", "ОТЛИЧНО!", "Excellent work, comrade!", "", "ВПЕРЁД! · ONWARD!", "next")
	_card(root, "over", "☢", "ИГРА ОКОНЧЕНА", "Game over", "Не сдавайся, товарищ!\nDon't give up, comrade! Try this level again.", "ЕЩЁ РАЗ · AGAIN", "retry")
	_card(root, "win", "★", "ТЫ НАСТОЯЩИЙ ГЕРОЙ, ТОВАРИЩ!", "You are a real hero, comrade!", "Энергоблок №4 восстановлен!\nBlock No. 4 has been rebuilt and the smoke has stopped.\nOleg earns the medal \"Hero of Labour\"!", "ИГРАТЬ СНОВА · PLAY AGAIN", "again")
	fade_rect = _tint(root, Color(0, 0, 0, 0))
	show_card("menu")

# ------------------------------------------------------------ builders
func _tint(parent: Control, col: Color) -> ColorRect:
	var r := ColorRect.new(); r.set_anchors_preset(Control.PRESET_FULL_RECT); r.color = col; r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r); return r

func _box(bg: Color, border: Color, bw: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = bg; s.border_color = border; s.set_border_width_all(bw); s.set_corner_radius_all(radius)
	s.content_margin_left = 10; s.content_margin_right = 10; s.content_margin_top = 6; s.content_margin_bottom = 6
	return s

func _label(parent: Node, text: String, size: int, col: Color, heading: bool) -> Label:
	var l := Label.new(); l.text = text
	l.add_theme_font_size_override("font_size", size); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); l.add_theme_constant_override("outline_size", max(2, size / 6))
	if heading:
		l.add_theme_font_override("font", head_font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l); return l

func _pill(parent: Node, cap: String, val: String, col: Color) -> Label:
	var p := PanelContainer.new(); p.add_theme_stylebox_override("panel", _box(Color(0.1, 0.08, 0.06, 0.8), Color("#8a2a1e"), 2, 6))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(p)
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 8); p.add_child(h)
	_label(h, cap, 12, GOLD, true).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return _label(h, val, 20, col, true)

func _small_button(parent: Control, text: String, pos: Vector2) -> Button:
	var b := Button.new(); b.text = text; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _box(Color(0.1, 0.08, 0.06, 0.8), Color("#8a2a1e"), 2, 6))
	b.add_theme_stylebox_override("hover", _box(Color(0.2, 0.12, 0.08, 0.9), Color("#d9a441"), 2, 6))
	b.add_theme_stylebox_override("pressed", _box(Color(0.2, 0.12, 0.08, 0.9), Color("#d9a441"), 2, 6))
	b.add_theme_font_override("font", head_font); b.add_theme_font_size_override("font_size", 15)
	b.set_anchors_preset(Control.PRESET_TOP_RIGHT); b.position = pos; b.custom_minimum_size = Vector2(44, 40)
	parent.add_child(b); return b

func _card(parent: Control, id: String, icon: String, title: String, sub: String, body: String, btn: String, action: String) -> void:
	var dim := ColorRect.new(); dim.set_anchors_preset(Control.PRESET_FULL_RECT); dim.color = Color(0, 0, 0, 0.55); parent.add_child(dim)
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); dim.add_child(cc)
	var p := PanelContainer.new(); var sb := _box(Color("#221b15"), Color("#a1281c"), 4, 6)
	sb.content_margin_left = 34; sb.content_margin_right = 34; sb.content_margin_top = 22; sb.content_margin_bottom = 24
	p.add_theme_stylebox_override("panel", sb); p.custom_minimum_size = Vector2(560, 0); cc.add_child(p)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 8); v.alignment = BoxContainer.ALIGNMENT_CENTER; p.add_child(v)
	var ic := Control.new(); ic.custom_minimum_size = Vector2(0, 44); v.add_child(ic)
	ic.draw.connect(func(): ic.draw_colored_polygon(star_pts(Vector2(ic.size.x / 2.0, 22), 20), Color("#d0302a")))
	var t := _label(v, title, 52 if title.length() < 16 else 34, Color("#e0392b"), true); t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; t.custom_minimum_size = Vector2(490, 0)
	var s := _label(v, sub, 22, GOLD, true); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bd := _label(v, body, 17, CREAM, false); bd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; bd.custom_minimum_size = Vector2(490, 0)
	var b := Button.new(); b.text = btn; b.focus_mode = Control.FOCUS_NONE
	b.add_theme_stylebox_override("normal", _box(Color("#a82b20"), GOLD, 2, 4)); b.add_theme_stylebox_override("hover", _box(Color("#c4372a"), GOLD, 2, 4))
	b.add_theme_stylebox_override("pressed", _box(Color("#8a1f15"), GOLD, 2, 4))
	b.add_theme_font_override("font", head_font); b.add_theme_font_size_override("font_size", 22); b.add_theme_color_override("font_color", Color("#fff3d0"))
	b.custom_minimum_size = Vector2(0, 52); b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func(): pressed.emit(action)); v.add_child(b)
	dim.visible = false
	cards[id] = {"root": dim, "title": t, "sub": s, "body": bd}

func _big_button(parent: Node, text: String, action: String, primary: bool) -> Button:
	var b := Button.new(); b.text = text; b.focus_mode = Control.FOCUS_NONE; b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var bg := Color("#a82b20") if primary else Color(0.12, 0.09, 0.07, 0.85)
	b.add_theme_stylebox_override("normal", _box(bg, GOLD if primary else Color("#8a2a1e"), 2, 4))
	b.add_theme_stylebox_override("hover", _box(bg.lightened(0.15), GOLD, 2, 4))
	b.add_theme_stylebox_override("pressed", _box(bg.darkened(0.2), GOLD, 2, 4))
	b.add_theme_font_override("font", head_font); b.add_theme_font_size_override("font_size", 26 if primary else 19)
	b.add_theme_color_override("font_color", Color("#fff3d0")); b.custom_minimum_size = Vector2(380, 62 if primary else 46)
	b.pressed.connect(func(): pressed.emit(action)); parent.add_child(b)
	return b

## Main menu: title and buttons on the left, the hero shot of Oleg stays visible on the right.
func _menu(parent: Control) -> void:
	var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(root)
	var g := Gradient.new(); g.set_color(0, Color(0.04, 0.03, 0.02, 0.88)); g.set_color(1, Color(0.04, 0.03, 0.02, 0.0)); g.add_point(0.55, Color(0.04, 0.03, 0.02, 0.6))
	var gt := GradientTexture2D.new(); gt.gradient = g; gt.fill_from = Vector2(0, 0.5); gt.fill_to = Vector2(1, 0.5); gt.width = 256; gt.height = 4
	var shade := TextureRect.new(); shade.texture = gt; shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.anchor_bottom = 1.0; shade.anchor_right = 0.62; shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(shade)
	var top_bar := ColorRect.new(); top_bar.color = Color(0, 0, 0, 0.55); top_bar.anchor_right = 1.0; top_bar.offset_bottom = 34; top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(top_bar)
	var bot_bar := ColorRect.new(); bot_bar.color = Color(0, 0, 0, 0.55); bot_bar.anchor_right = 1.0; bot_bar.anchor_top = 1.0; bot_bar.anchor_bottom = 1.0; bot_bar.offset_top = -34
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(bot_bar)
	var v := VBoxContainer.new(); v.anchor_top = 0.5; v.anchor_bottom = 0.5; v.offset_left = 64; v.offset_top = -250; v.offset_bottom = 250
	v.add_theme_constant_override("separation", 10); v.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(v)
	var star := Control.new(); star.custom_minimum_size = Vector2(60, 56); v.add_child(star)
	star.draw.connect(func(): star.draw_colored_polygon(star_pts(Vector2(28, 28), 26), Color("#d0302a")); star.draw_polyline(star_pts(Vector2(28, 28), 26) + PackedVector2Array([star_pts(Vector2(28, 28), 26)[0]]), GOLD, 2.0))
	var t := _label(v, "ЧЕРНОБЫЛЬ", 92, Color("#e0392b"), true)
	t.add_theme_color_override("font_outline_color", Color("#3a0c06")); t.add_theme_constant_override("outline_size", 18)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7)); t.add_theme_constant_override("shadow_offset_y", 6)
	_label(v, "CHERNOBYL  ·  ЭНЕРГОБЛОК №4", 26, GOLD, true)
	var r := ColorRect.new(); r.custom_minimum_size = Vector2(420, 4); r.color = Color("#b3261e"); v.add_child(r)
	_label(v, "Товарищ Олег! Родина зовёт!", 24, CREAM, true)
	_label(v, "Comrade Oleg! The Motherland calls.\nRebuild Block No. 4 and stop the smoke.", 19, Color("#cdbf9a"), false)
	var sp := Control.new(); sp.custom_minimum_size = Vector2(0, 14); v.add_child(sp)
	_big_button(v, "ИГРАТЬ  ·  PLAY", "start", true)
	_big_button(v, "КАК ИГРАТЬ  ·  HOW TO PLAY", "help", false)
	var foot := _label(root, "A student game by DorkTeach   ·   Music: \"The Hero's March\"" + ("   ·   Click once to turn on the sound" if OS.has_feature("web") else ""), 14, Color("#cdbf9a"), false)
	foot.anchor_top = 1.0; foot.anchor_bottom = 1.0; foot.offset_left = 22; foot.offset_top = -27
	root.visible = false
	cards["menu"] = {"root": root, "title": t, "sub": t, "body": t}

# ------------------------------------------------------------ API
func show_card(id: String) -> void:
	for k in cards:
		cards[k].root.visible = (k == id)

func card_open(id: String) -> bool:
	return cards.has(id) and cards[id].root.visible

func set_card_text(id: String, title: String, sub: String, body: String) -> void:
	cards[id].title.text = title; cards[id].sub.text = sub; cards[id].body.text = body

func set_hud_visible(v: bool) -> void:
	hud_root.visible = v

func set_stats(lives: int, carry: int, built: int, need: int) -> void:
	lives_shown = lives; lives_l.custom_minimum_size.x = 22 * maxi(1, mini(lives, 8)); lives_l.queue_redraw()
	carry_l.text = str(carry); built_l.text = "%d/%d" % [built, need]

func set_level(t: String) -> void:
	lvl_l.text = t

func show_msg(ru: String, en: String, sec: float = 2.5) -> void:
	msg_ru.text = ru; msg_en.text = en; msg_t = sec

func subs(ru: String, en: String) -> void:
	sub_ru.text = ru; sub_en.text = en

func set_compass(angle: float, text: String) -> void:
	arrow.rotation = angle; ctext.text = text

func set_detector(v: float, hot: bool, needle_deg: float, dose: float, rad: float) -> void:
	reading.text = ("%.2f" % v) if v < 10.0 else ("%.1f" % v)
	reading.add_theme_color_override("font_color", Color("#ff6a4a") if hot else Color("#9dff6a"))
	needle = needle_deg; gauge.queue_redraw()
	dose_fill.size.x = 160.0 * clampf(dose / 100.0, 0.0, 1.0)
	dose_fill.color = Color("#8aff4a").lerp(Color("#ff3b2a"), clampf(dose / 100.0, 0.0, 1.0))
	rad_tint.color.a = clampf(dose / 100.0, 0.0, 1.0) * 0.32 + clampf(rad * 0.06, 0.0, 0.1)

func flash_led() -> void:
	led.color = Color("#ff3b2a")
	get_tree().create_timer(0.05).timeout.connect(func(): led.color = Color("#3a1010"))

func hit_flash() -> void:
	hit_tint.color.a = 0.5
	create_tween().tween_property(hit_tint, "color:a", 0.0, 0.8)

func fade(on: bool) -> void:
	create_tween().tween_property(fade_rect, "color:a", 1.0 if on else 0.0, 0.6)

func set_quality_text(hq: bool) -> void:
	quality_b.text = "HQ" if hq else "LQ"

func set_mute_text(m: bool) -> void:
	mute_b.text = "ТИХО" if m else "ЗВУК"

func _process(delta: float) -> void:
	var mv: Control = msg_ru.get_parent()
	if msg_t > 0.0:
		msg_t -= delta; mv.modulate.a = 1.0
	else:
		mv.modulate.a = maxf(0.0, mv.modulate.a - delta * 2.5)

static func star_pts(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.42
		p.append(c + Vector2(cos(a), sin(a)) * rr)
	return p

func _draw_lives() -> void:
	for i in mini(lives_shown, 8):
		lives_l.draw_colored_polygon(star_pts(Vector2(10 + i * 22, 13), 10), Color("#e0392b"))

func _draw_gauge() -> void:
	var ctr := Vector2(80, 64)
	gauge.draw_rect(Rect2(0, 0, 160, 66), Color("#ece2bf"))
	var segs := [[-70.0, -10.0, Color("#4c9a3a")], [-10.0, 30.0, Color("#d9b13a")], [30.0, 70.0, Color("#c0392b")]]
	for s in segs:
		gauge.draw_arc(ctr, 50, deg_to_rad(s[0] - 90.0), deg_to_rad(s[1] - 90.0), 24, s[2], 10.0)
	var a := deg_to_rad(needle - 90.0)
	gauge.draw_line(ctr, ctr + Vector2(cos(a), sin(a)) * 56.0, Color("#1a1a1a"), 3.0)
	gauge.draw_circle(ctr, 5, Color("#1a1a1a"))
