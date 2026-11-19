extends Node3D
## ЧЕРНОБЫЛЬ / CHERNOBYL — comrade Oleg rebuilds Block No. 4.
## A student game by DorkTeach. Everything (world, models, sound, UI) is generated in code.

const PMIN := Vector2(-56, -54)
const PMAX := Vector2(56, 58)
const PAD := Vector2(0, -15)
const PAD_R := 3.0
const START := Vector2(0, 46)
const FRONT := -24.0
const PATH := [Vector2(-80, 68), Vector2(-56, 64), Vector2(-34, 58), Vector2(-16, 52), Vector2(-4, 47.5)]
const STAGE_COUNTS := [6, 8, 8]
const STAGE_START := [0, 6, 14]
const TOTAL_PIECES := 22.0

var LEVELS := [
	{"ru": "ПРИБЫТИЕ", "en": "The Arrival", "tip_ru": "Собери стройматериалы и неси их на стройку!", "tip_en": "Collect building materials and carry them to the construction site!",
	 "mats": 6, "guards": 1, "zones": 5, "zone_s": 1.0, "traps": 0, "debris": false, "gap": [4.0, 6.0], "tokens": 1, "ground": "grass",
	 "sky_top": 0x4b5563, "sky_hor": 0xa8aaa0, "fog": 0x9a9d94, "fog_near": 25.0, "fog_far": 170.0, "amb": 0xc8ccc0, "amb_e": 0.4, "sun": 0xffe6c0, "sun_e": 0.85,
	 "plight": 0.0, "dust": 0xe8e2c0, "transpose": 0,
	 "done_ru": "НИЖНИЕ СТЕНЫ ГОТОВЫ!", "done_en": "The lower walls of Block 4 stand again!", "done_txt": "Molodets! Next, the ghost town of Pripyat, to find materials for the walls of the reactor hall."},
	{"ru": "ПРИПЯТЬ", "en": "The Ghost Town", "tip_ru": "Осторожно! Сверху падает мусор и ловушки.", "tip_en": "Careful! Junk falls from above. Red circles = move away!",
	 "mats": 8, "guards": 2, "zones": 6, "zone_s": 1.25, "traps": 3, "debris": true, "gap": [3.2, 5.0], "tokens": 2, "ground": "ash",
	 "sky_top": 0x22222e, "sky_hor": 0x9a7f70, "fog": 0x6e6466, "fog_near": 18.0, "fog_far": 135.0, "amb": 0xb0a8b0, "amb_e": 0.34, "sun": 0xffc89a, "sun_e": 0.65,
	 "plight": 0.5, "dust": 0xb0aaa0, "transpose": -3,
	 "done_ru": "ЗАЛ РЕАКТОРА СТОИТ!", "done_en": "The reactor hall has walls again!", "done_txt": "Khorosho! One last job: a new roof over the reactor hall, so the smoke finally stops. Into the night, comrade!"},
	{"ru": "АКТИВНАЯ ЗОНА", "en": "The Reactor Zone", "tip_ru": "Ночь. Сильная радиация. Будь храбрым!", "tip_en": "Night. Strong radiation. Be brave and finish the reactor!",
	 "mats": 8, "guards": 3, "zones": 7, "zone_s": 1.5, "traps": 4, "debris": true, "gap": [2.4, 3.8], "tokens": 2, "ground": "concrete",
	 "sky_top": 0x05070d, "sky_hor": 0x222c38, "fog": 0x1a2228, "fog_near": 14.0, "fog_far": 115.0, "amb": 0x8ea0b8, "amb_e": 0.28, "sun": 0x9fb4ff, "sun_e": 0.45,
	 "plight": 1.4, "dust": 0x9dff9a, "transpose": -5, "done_ru": "", "done_en": "", "done_txt": ""}
]

const MATS := [
	{"id": "concrete", "ru": "Бетон", "en": "Concrete", "c": 0xbfc4c8},
	{"id": "steel", "ru": "Сталь", "en": "Steel", "c": 0xff9a4a},
	{"id": "lead", "ru": "Свинец", "en": "Lead", "c": 0x8ab0ff},
	{"id": "brick", "ru": "Кирпич", "en": "Bricks", "c": 0xff6a5a}]
const HURT := {"guard": ["СТОЙ! Кто идёт?", "Halt! The guard sent you back!"], "debris": ["БАМ! Осторожно!", "Bonk! Watch out for falling junk!"],
	"trap": ["БУМ! Ловушка!", "Boom! A ceiling trap!"], "rad": ["Слишком много радиации!", "Too much radiation! Back to safety!"]}

# ------------------------------------------------------------ nodes / resources
var env: Environment
var sky_mat: ProceduralSkyMaterial
var sun: DirectionalLight3D
var cam: Camera3D
var hud
var sfx
var world: Node3D
var plight: OmniLight3D
var fill: DirectionalLight3D
var clouds: Node3D
var cloud_mat: StandardMaterial3D
var birch_tex: ImageTexture
var grass_mat: ShaderMaterial
var march: AudioStreamPlayer
var flag_mat: ShaderMaterial
var menu_t := 0.0
const HERO := Vector2(3.0, 37.0)
var oleg := {}
var rng := RandomNumberGenerator.new()

var facade_mat: StandardMaterial3D
var facade2_mat: StandardMaterial3D
var conc_mat: StandardMaterial3D
var fence_mat: StandardMaterial3D
var hazard_mat: StandardMaterial3D
var boom_mat: StandardMaterial3D
var stack_mat: StandardMaterial3D
var star_mat: StandardMaterial3D
var ground_tex: ImageTexture
var sign_tex: ImageTexture
var glow_tex: GradientTexture2D
var smoke_tex: ImageTexture
var star_mesh: ArrayMesh
var dot_mat: StandardMaterial3D
var burst_mesh: SphereMesh

# ------------------------------------------------------------ state
var circles: Array = []      # Vector3(x, z, r)
var boxes: Array = []        # Rect2 in x/z
var reserved: Array = []
var items: Array = []
var tokens: Array = []
var zones: Array = []
var guards: Array = []
var debris: Array = []
var traps: Array = []
var lamps: Array = []
var pieces: Array = []
var blinkers: Array = []
var pops: Array = []
var queue: Array = []
var anims: Array = []
var smoke: CPUParticles3D
var smoke_mat: StandardMaterial3D
var core_glow: MeshInstance3D
var core_light: OmniLight3D
var dust: CPUParticles3D
var pad_beam: MeshInstance3D
var pad_star: MeshInstance3D
var crane := {}
var bike := {}

var li := 0
var state := "menu"
var lives := 3
var built := 0
var need := 6
var queue_t := 0.0
var done_t := -1.0
var shake := 0.0
var play_t := 0.0
var cut := {}
var won_t := 0.0
var said := false
var clock_t := 0.0
var rad_rate := 0.0
var debris_t := 3.0
var smoke_level := 1.0
var smoke_target := 1.0
var hq := true
var muted := false
var cam_yaw := 0.0
var cam_pitch := 0.42
var cam_dist := 10.0
var dragging := false
var photo := false
var manual_cam := 0.0
var level_t := 0.0
var lost_level := 0
var save := {"unlocked": 0, "stars": [0, 0, 0], "hq": -1}
var aq := {"t": 0.0, "n": 0, "done": false}
var radio_done := {}
var crane_pc = null
var crane_hook := Vector2.ZERO
var crane_vel := Vector2.ZERO
var crane_sway := Vector2.ZERO
var crane_drop := -1.0
var crane_y := 0.0
var crane_slab_y := 0.0
var crane_creak := 0.0
var crane_outline: MeshInstance3D
var crane_cable: ImmediateMesh
var weather: CPUParticles3D
var step_phase := 0
var raw_delta := 0.016
const PAR := [180.0, 240.0, 300.0]
const SAVE_PATH := "user://chernobyl_save.json"
const LOAD_FACTS := [
	"The accident happened on 26 April 1986, during a safety test at Reactor No. 4 of the Chernobyl power plant in what is now Ukraine.",
	"The Exclusion Zone around the plant covers about 2,600 square kilometres. Today wolves, elk and rare Przewalski's horses live there.",
	"The \"Red Forest\" near the plant got its name because the pine trees turned reddish-brown and died from the radiation.",
	"The last working reactor at Chernobyl, Reactor No. 3, was shut down in December 2000.",
	"Radiation can't be seen, heard or smelled. That is why workers carried dosimeters to measure it.",
	"Lead is very good at blocking radiation, which is why it is used in shielding and protective aprons."]
const LEVEL_FACTS := [
	"A dosimeter like the DP-5 measures how much radiation is in the air around you. The needle shows the dose rate, and the clicks come faster when the radiation gets stronger.",
	"Pripyat was built in 1970 for the families of the power plant workers, and about 49,000 people lived there. The whole town was evacuated on 27 April 1986, the day after the accident. It is still empty today.",
	"In real life Block No. 4 was never rebuilt. A few months after the accident, workers covered it with a huge concrete and steel shell called the \"sarcophagus\". In 2016 an even bigger steel arch, the New Safe Confinement, was slid over it."]
var photo_t := 0.0
var P := {"x": 0.0, "z": 0.0, "y": 0.0, "face": PI, "walk": 0.0, "inv": 0.0, "carry": 0, "dose": 0.0, "cp": Vector2.ZERO, "moving": false, "cheer": 0.0}

func R(a: float, b: float) -> float:
	return rng.randf_range(a, b)

func pick(arr: Array):
	return arr[rng.randi() % arr.size()]

func C(hex: int, a: float = 1.0) -> Color:
	return Mk.c(hex, a)

# ============================================================ setup
func _ready() -> void:
	hq = not (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))
	_make_resources()
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new(); sky_mat = ProceduralSkyMaterial.new(); sky.sky_material = sky_mat; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.05
	env.glow_enabled = true; env.glow_intensity = 0.6; env.glow_bloom = 0.04; env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true; env.adjustment_saturation = 1.08; env.adjustment_contrast = 1.05
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_sky_affect = 0.35
	var we = WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, -40, 0); sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS; sun.directional_shadow_max_distance = 90.0
	sun.shadow_bias = 0.05; sun.shadow_normal_bias = 1.2; sun.shadow_blur = 1.6; add_child(sun)
	fill = DirectionalLight3D.new(); fill.rotation_degrees = Vector3(-22, 140, 0); fill.light_color = C(0x9fb4d8); fill.light_energy = 0.28; add_child(fill)
	clouds = Node3D.new(); add_child(clouds); make_clouds()
	plight = OmniLight3D.new(); plight.omni_range = 16; plight.light_color = C(0xd8ffd0); add_child(plight)
	cam = Camera3D.new(); cam.fov = 55; cam.far = 900; add_child(cam); cam.current = true
	sfx = preload("res://scripts/synth.gd").new(); add_child(sfx)
	hud = preload("res://scripts/hud.gd").new(); add_child(hud)
	hud.pressed.connect(_on_hud)
	march = AudioStreamPlayer.new(); add_child(march)
	var ms = load("res://music/heros_march.ogg")
	if ms:
		ms.loop = true; march.stream = ms; march.volume_db = -3.0
	oleg = make_oleg(); add_child(oleg.root)
	load_level(0)
	P.y = h(START.x, START.y)
	load_save()
	if int(save.hq) >= 0:
		hq = int(save.hq) == 1; aq.done = true
	set_quality(hq)
	hud.set_hud_visible(false)
	enter_menu()

func _make_resources() -> void:
	seed(7)
	facade_mat = Mk.tri(Mk.facade(false), Vector3(1.0 / 6.0, 1.0 / 8.0, 1.0 / 6.0))
	facade_mat.emission_enabled = true; facade_mat.emission = C(0xffd27a); facade_mat.emission_texture = Mk.facade(true); facade_mat.emission_energy_multiplier = 0.0
	facade2_mat = facade_mat.duplicate(); facade2_mat.albedo_color = C(0xe8e5dc)
	conc_mat = Mk.tri(Mk.tex(Mk.noise_img(C(0xbdbab2), [C(0x8c8a84), C(0xd8d4cc), C(0x6e6c66)], 900)), Vector3(0.5, 0.5, 0.5))
	fence_mat = Mk.tri(Mk.fence(), Vector3(0.25, 1.0 / 2.6, 0.25))
	hazard_mat = Mk.tri(Mk.hazard(), Vector3(0.5, 0.5, 0.5))
	boom_mat = StandardMaterial3D.new(); boom_mat.albedo_texture = Mk.stripes(C(0xc0241a), C(0xf2eee4), 8, false, 256, 16); boom_mat.uv1_triplanar = true
	stack_mat = StandardMaterial3D.new(); stack_mat.albedo_texture = Mk.stripes(C(0xb3261e), C(0xe6e2d8), 12, true); stack_mat.roughness = 0.9
	star_mat = StandardMaterial3D.new(); star_mat.albedo_color = C(0xc0241a); star_mat.emission_enabled = true; star_mat.emission = C(0xff2010)
	star_mat.emission_energy_multiplier = 0.4; star_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ground_tex = Mk.tex(Mk.noise_img(C(0xc8c8c8), [Color.WHITE, C(0x8a8a8a), C(0xa0a0a0), C(0xe0e0e0)], 1400))
	sign_tex = Mk.radiation_sign()
	glow_tex = Mk.radial(Color(1, 1, 1, 1), Color(1, 1, 1, 0))
	star_mesh = Mk.star_mesh()
	dot_mat = Mk.glow(Color.WHITE, false); dot_mat.vertex_color_use_as_albedo = true
	burst_mesh = SphereMesh.new(); burst_mesh.radius = 0.5; burst_mesh.height = 1.0; burst_mesh.radial_segments = 6; burst_mesh.rings = 3
	burst_mesh.material = dot_mat
	var img = Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	var blobs = []
	for i in 10:
		blobs.append(Vector3(40 + randf() * 48, 40 + randf() * 48, 22 + randf() * 26))
	for y in 128:
		for x in 128:
			var a = 0.0
			for b in blobs:
				var d = Vector2(x - b.x, y - b.y).length() / b.z
				if d < 1.0:
					a += (1.0 - d) * 0.7
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	smoke_tex = Mk.tex(img)
	var bark = Image.create_empty(32, 128, false, Image.FORMAT_RGBA8); bark.fill(C(0xe8e4da))
	for i in 26:
		bark.fill_rect(Rect2i(randi() % 26, randi() % 124, 4 + randi() % 10, 2 + randi() % 3), C(0x2a2826))
	Mk.speckle(bark, 200, [C(0xc8c4ba), C(0x9a968e)], 0.4)
	birch_tex = Mk.tex(bark)
	var ci = Image.create_empty(128, 64, false, Image.FORMAT_RGBA8)
	var cb = []
	for i in 16:
		var cx = 18 + randf() * 92
		cb.append(Vector3(cx, 34 + randf() * 12 - absf(cx - 64) * 0.12, 10 + randf() * 14))
	for y in 64:
		for x in 128:
			var a = 0.0
			for b in cb:
				var d = Vector2((x - b.x) * 0.8, y - b.y).length() / b.z
				if d < 1.0: a += (1.0 - d) * 0.45
			ci.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 0.95) * clampf((60.0 - y) / 20.0, 0.0, 1.0)))
	cloud_mat = Mk.glow(Color(1, 1, 1, 0.7), false, Mk.tex(ci)); cloud_mat.disable_fog = true; cloud_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var sh = Shader.new()
	sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform vec3 base_col = vec3(0.25, 0.3, 0.12);
uniform vec3 tip_col = vec3(0.6, 0.62, 0.3);
varying float hgt;
void vertex() {
	hgt = clamp((VERTEX.y + 0.3) / 0.6, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float s = sin(TIME * 1.7 + wp.x * 0.35 + wp.z * 0.27) * 0.13 * hgt * hgt;
	VERTEX.x += s; VERTEX.z += s * 0.6;
}
void fragment() {
	ALBEDO = mix(base_col, tip_col, hgt) * COLOR.rgb;
	ROUGHNESS = 0.9;
	BACKLIGHT = vec3(0.25) * hgt;
}"""
	grass_mat = ShaderMaterial.new(); grass_mat.shader = sh

# ============================================================ terrain
func h(x: float, z: float) -> float:
	var base = 0.5 * sin(x * 0.09 + li) * cos(z * 0.11 - li) + 0.3 * sin(x * 0.23 + z * 0.17)
	var dx = maxf(maxf(-66.0 - x, 0.0), x - 30.0)
	var dz = maxf(maxf(-80.0 - z, 0.0), z + 4.0)
	var flat = clampf((Vector2(dx, dz).length() - 2.0) / 14.0, 0.0, 1.0)
	var outer = maxf(0.0, absf(x) - 62.0) * 0.25 + maxf(0.0, -z - 62.0) * 0.15 + maxf(0.0, z - 66.0) * 0.1
	if li == 0:
		return 9.0 / (1.0 + exp(-(z - 24.0) / 6.0)) + (base * 1.4 + outer) * flat
	return (base * (0.25 if li == 2 else 0.7) + outer) * flat

func path_x(z: float) -> float:
	for i in PATH.size() - 1:
		var a: Vector2 = PATH[i]; var b: Vector2 = PATH[i + 1]
		if z <= a.y and z >= b.y:
			return lerpf(a.x, b.x, (a.y - z) / (a.y - b.y))
	return 999.0

func make_terrain(type: String) -> void:
	var N = 120; var S = 320.0
	var pal: Array = {"grass": [0x5c6a34, 0x7c7a40, 0x6a5a38], "ash": [0x5a554c, 0x6e655a, 0x48443e], "concrete": [0x45484a, 0x55585a, 0x3a3a38]}[type]
	var st = SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in N + 1:
		for i in N + 1:
			var x = -S / 2.0 + S * i / N; var z = -S / 2.0 + S * j / N
			var y = h(x, z)
			var n = 0.5 + 0.5 * sin(x * 0.13 + cos(z * 0.07) * 2.0) * cos(z * 0.11)
			var col = C(pal[0]).lerp(C(pal[1]), n).lerp(C(pal[2]), maxf(0.0, sin(x * 0.05 + z * 0.04)) * 0.6)
			if z < -5 and z > -30 and x > -62 and x < 34:
				col = C(0x55575a if type == "concrete" else 0x6a6862).lerp(C(0x4a4844), n * 0.5)
			elif absf(x) < 3.2 and z > -6 and z < 34:
				col = C(0x3c3c3a).lerp(C(0x4a4a46), n * 0.4)
			elif type == "grass" and absf(x - path_x(z)) < 2.2 and z > 40:
				col = col.lerp(C(0x7a6a4a), 0.7)
			var e = 1.0
			st.set_normal(Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized())
			st.set_color(col); st.set_uv(Vector2(x, z) * 0.22)
			st.add_vertex(Vector3(x, y, z))
	for j in N:
		for i in N:
			var a = j * (N + 1) + i
			st.add_index(a); st.add_index(a + N + 1); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(a + N + 1); st.add_index(a + N + 2)
	var m = StandardMaterial3D.new(); m.vertex_color_use_as_albedo = true; m.albedo_texture = ground_tex; m.roughness = 1.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node = Mk.mi(world, st.commit(), m, Vector3.ZERO)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# ============================================================ placement helpers
func is_free(x: float, z: float, r: float) -> bool:
	if x < PMIN.x + r or x > PMAX.x - r or z < PMIN.y + r or z > PMAX.y - r:
		return false
	for c in circles:
		if Vector2(x - c.x, z - c.y).length() < c.z + r:
			return false
	for b in boxes:
		if x > b.position.x - r and x < b.end.x + r and z > b.position.y - r and z < b.end.y + r:
			return false
	for c in reserved:
		if Vector2(x - c.x, z - c.y).length() < c.z + r:
			return false
	return true

func spot(r: float, extra: Callable = Callable(), tries: int = 300):
	for k in tries:
		var x = R(PMIN.x, PMAX.x); var z = R(PMIN.y, PMAX.y)
		if is_free(x, z, r) and (not extra.is_valid() or extra.call(x, z)):
			return Vector2(x, z)
	return null

func add_box_col(x: float, z: float, w: float, d: float) -> void:
	boxes.append(Rect2(x - w / 2.0, z - d / 2.0, w, d))

func B(parent: Node, mat: Material, x: float, y: float, z: float, w: float, hh: float, d: float) -> MeshInstance3D:
	return Mk.box(parent, mat, Vector3(x, y, z), Vector3(w, hh, d))

# ============================================================ decor
func birch(x: float, z: float) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); g.rotation = Vector3(0, R(0, 6), R(-0.06, 0.06)); world.add_child(g)
	var bm = StandardMaterial3D.new(); bm.albedo_texture = birch_tex; bm.roughness = 0.85
	var trunk = CylinderMesh.new(); trunk.top_radius = 0.1; trunk.bottom_radius = 0.2; trunk.height = 6.5; trunk.radial_segments = 8
	Mk.mi(g, trunk, bm, Vector3(0, 3.25, 0))
	for k in 3:
		var a = Vector3(0, R(3.2, 5.2), 0)
		Mk.cyl_between(g, a, a + Vector3(R(-1.4, 1.4), R(0.8, 1.6), R(-1.4, 1.4)), 0.05, bm)
	var leaf = SphereMesh.new(); leaf.radius = 1.0; leaf.height = 2.0; leaf.radial_segments = 8; leaf.rings = 5
	var cols = [0xa49a3a, 0xc0892a, 0x7f8a3c, 0x9a7a2a, 0xb8a040]
	for k in 8:
		var lm = pbr(pick(cols), 0.9); lm.backlight_enabled = true; lm.backlight = C(0x6a5a20)
		Mk.mi(g, leaf, lm, Vector3(R(-1.3, 1.3), R(5.0, 7.6), R(-1.3, 1.3)), Vector3(R(0.8, 1.4), R(0.7, 1.1), R(0.8, 1.4)))
	circles.append(Vector3(x, z, 0.45))

func dead_tree(x: float, z: float) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); g.rotation.y = R(0, 6); world.add_child(g)
	var m = Mk.lam(0x3a3128)
	Mk.cyl_between(g, Vector3.ZERO, Vector3(0, 5, 0), 0.22, m)
	for k in 4:
		var a = Vector3(0, R(2.5, 4.5), 0)
		Mk.cyl_between(g, a, a + Vector3(R(-1.8, 1.8), R(0.8, 2), R(-1.8, 1.8)), 0.07, m)
	circles.append(Vector3(x, z, 0.45))

func house(x: float, z: float) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); world.add_child(g)
	B(g, Mk.lam(0x6b5642), 0, 1.5, 0, 6, 3, 5)
	for a in [-1.6, 1.6]:
		B(g, Mk.lam(0x1d1a17), a, 1.7, 2.51, 1, 1, 0.1)
	B(g, Mk.lam(0x1d1a17), 0, 1.1, 2.51, 1, 2.2, 0.1)
	B(g, Mk.lam(0x4a4038), 0, 3.6, -1.3, 6.4, 0.25, 3.2).rotation.x = 0.5
	B(g, Mk.lam(0x4a4038), 1.5, 1.4, 1.8, 3.4, 0.25, 3).rotation = Vector3(-1.1, 0, 0.3)
	add_box_col(x, z, 6, 5)

func car(x: float, z: float) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); g.rotation = Vector3(0, R(0, 6), R(-0.08, 0.08)); world.add_child(g)
	var c = Mk.lam(pick([0x7a4a2a, 0x5a6a5a, 0x8a7a5a, 0x6a4a3a]))
	B(g, c, 0, 0.75, 0, 3.6, 0.8, 1.7); B(g, c, -0.3, 1.5, 0, 2, 0.8, 1.6); B(g, Mk.lam(0x1c2226), -0.3, 1.5, 0, 2.02, 0.5, 1.62)
	for p in [Vector2(-1.2, 0.85), Vector2(1.2, 0.85), Vector2(-1.2, -0.85), Vector2(1.2, -0.85)]:
		Mk.mi(g, Mk.CYL, Mk.lam(0x1a1a1a), Vector3(p.x, 0.35, p.y), Vector3(0.38, 0.25, 0.38)).rotation.x = PI / 2
	circles.append(Vector3(x, z, 1.9))

func rad_sign(x: float, z: float) -> void:
	var y = h(x, z)
	Mk.mi(world, Mk.CYL, Mk.lam(0x333333), Vector3(x, y + 1.1, z), Vector3(0.05, 2.2, 0.05))
	var q = QuadMesh.new(); q.size = Vector2(0.8, 1.0)
	var m = StandardMaterial3D.new(); m.albedo_texture = sign_tex; m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var s = Mk.mi(world, q, m, Vector3(x, y + 2.2, z))
	s.rotation = Vector3(0, atan2(START.x - x, START.y - z) + R(-0.4, 0.4), R(-0.12, 0.12))

func bale(x: float, z: float) -> void:
	var m = Mk.mi(world, Mk.CYL, Mk.lam(0xa38c4c), Vector3(x, h(x, z) + 1, z), Vector3(1, 1.4, 1))
	m.rotation = Vector3(0, R(0, 3), PI / 2); circles.append(Vector3(x, z, 1.1))

func apt(x: float, z: float, w: float, d: float, hh: float) -> void:
	var y = h(x, z)
	B(world, facade2_mat, x, y + hh / 2.0 - 0.3, z, w, hh, d)
	B(world, Mk.lam(0x4a4844), x, y + hh - 0.15, z, w + 0.3, 0.3, d + 0.3)
	for k in 3:
		B(world, Mk.lam(0x7d7a72), x + R(-w / 2.5, w / 2.5), y + hh + R(0, 1.5), z + R(-d / 2.5, d / 2.5), R(1, 3), R(1, 3), R(1, 3)).rotation = Vector3(R(0, 1), R(0, 1), R(0, 1))
	add_box_col(x, z, w, d)

func ferris(x: float, z: float) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); g.rotation.y = atan2(-x, -z + 20) + PI / 2; world.add_child(g)
	var yel = Mk.lam(0xc9a227); var rust = Mk.lam(0x6a5a3a)
	for s in [-1, 1]:
		var t = TorusMesh.new(); t.inner_radius = 10.8; t.outer_radius = 11.2; t.rings = 48; t.ring_segments = 6
		var tn = Mk.mi(g, t, yel, Vector3(0, 13, s)); tn.rotation.x = PI / 2
		Mk.cyl_between(g, Vector3(-6, 0, s * 2.5), Vector3(0, 13, s), 0.3, rust)
		Mk.cyl_between(g, Vector3(6, 0, s * 2.5), Vector3(0, 13, s), 0.3, rust)
	for k in 12:
		var a = k / 12.0 * TAU
		var p = Vector3(cos(a) * 11, 13 + sin(a) * 11, 0)
		Mk.cyl_between(g, Vector3(0, 13, 0), p, 0.08, yel)
		B(g, Mk.lam(0xd9b43a), p.x, p.y - 1.1, 0, 1.4, 1.2, 1.4)

func cooling_tower(x: float, z: float, s: float = 1.0) -> void:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z) - 1, z); g.scale = Vector3.ONE * s; world.add_child(g)
	var m = Mk.lam(0x8a8a84)
	for i in 16:
		var y0 = i / 16.0 * 40.0; var y1 = (i + 1) / 16.0 * 40.0
		var r0 = 9.0 * sqrt(1.0 + pow((y0 - 28.0) / 20.0, 2)); var r1 = 9.0 * sqrt(1.0 + pow((y1 - 28.0) / 20.0, 2))
		var cm = CylinderMesh.new(); cm.bottom_radius = r0; cm.top_radius = r1; cm.height = y1 - y0; cm.radial_segments = 28; cm.cap_top = false; cm.cap_bottom = false
		Mk.mi(g, cm, m, Vector3(0, (y0 + y1) / 2.0, 0))

func lamp_post(x: float, z: float, with_light: bool) -> void:
	var y = h(x, z); var m = Mk.lam(0x3a3c3e)
	Mk.mi(world, Mk.CYL, m, Vector3(x, y + 3, z), Vector3(0.08, 6, 0.08))
	B(world, m, x + 0.6, y + 6, z, 1.4, 0.12, 0.12); B(world, Mk.lam(0x222222), x + 1.2, y + 5.85, z, 0.5, 0.25, 0.35)
	var bm = Mk.glow(C(0xffd08a) if with_light else C(0x555555), false)
	var bulb = Mk.mi(world, Mk.SPH, bm, Vector3(x + 1.2, y + 5.7, z), Vector3.ONE * 0.14)
	circles.append(Vector3(x, z, 0.25))
	if with_light:
		var L = OmniLight3D.new(); L.light_color = C(0xffc27a); L.omni_range = 20; L.light_energy = 1.4; L.position = Vector3(x + 1.2, y + 5.4, z)
		world.add_child(L); lamps.append({"L": L, "bulb": bm, "ph": R(0, 9)})

func container(x: float, z: float, rot: bool) -> void:
	var y = h(x, z); var w = 2.4 if rot else 6.0; var d = 6.0 if rot else 2.4
	B(world, Mk.lam(pick([0x5a6f86, 0x8a3f33, 0x6f7a4a, 0x8a7a5a])), x, y + 1.3, z, w, 2.6, d)
	for k in range(-2, 3):
		B(world, Mk.lam(0x3a3a36), x + (0.0 if rot else k * 1.1), y + 1.3, z + (k * 1.1 if rot else 0.0), w + 0.04 if rot else 0.08, 2.4, 0.08 if rot else d + 0.04)
	add_box_col(x, z, w, d)

func barrier(x: float, z: float, rot: bool) -> void:
	var y = h(x, z); var w = 0.6 if rot else 2.6; var d = 2.6 if rot else 0.6
	B(world, Mk.lam(0x9a968c), x, y + 0.5, z, w, 1, d); B(world, hazard_mat, x, y + 0.75, z, w + 0.02, 0.25, d + 0.02)
	add_box_col(x, z, w, d)

func rubble(x: float, z: float, n: int, sp: float) -> void:
	var y = h(x, z)
	for k in n:
		B(world, Mk.lam(pick([0x6e6b64, 0x5a5852, 0x7d7a72, 0x4a4844])), x + R(-sp, sp), y + R(0, 0.5), z + R(-sp, sp), R(0.4, 1.6), R(0.3, 1.1), R(0.4, 1.6)).rotation = Vector3(R(0, 1), R(0, 3), R(0, 1))
	if sp > 0.8:
		circles.append(Vector3(x, z, sp * 0.75))

func pipe_run(x1: float, z: float, x2: float) -> void:
	var y0 = h((x1 + x2) / 2.0, z)
	Mk.cyl_between(world, Vector3(x1, y0 + 4.2, z), Vector3(x2, y0 + 4.2, z), 0.55, Mk.lam(0x7a6a52))
	var x = minf(x1, x2) + 2.0
	while x < maxf(x1, x2):
		B(world, Mk.lam(0x4a4a48), x, y0 + 1.9, z, 0.3, 3.8, 0.3); B(world, Mk.lam(0x4a4a48), x, y0 + 3.65, z, 0.3, 0.2, 1.6)
		circles.append(Vector3(x, z, 0.35)); x += 7.0

func pylon(x: float, z: float) -> Array:
	var y = h(x, z); var segs = []; var Ht = 20.0
	var V = func(a: float, b: float, c: float) -> Vector3: return Vector3(x + a, y + b, z + c)
	var hh = 0.0
	while hh < Ht:
		var w1 = lerpf(1.8, 0.5, hh / Ht); var w2 = lerpf(1.8, 0.5, (hh + 2.5) / Ht)
		var c1 = [Vector2(-w1, -w1), Vector2(w1, -w1), Vector2(w1, w1), Vector2(-w1, w1)]
		var c2 = [Vector2(-w2, -w2), Vector2(w2, -w2), Vector2(w2, w2), Vector2(-w2, w2)]
		for k in 4:
			var n = (k + 1) % 4
			segs.append([V.call(c1[k].x, hh, c1[k].y), V.call(c2[k].x, hh + 2.5, c2[k].y)])
			segs.append([V.call(c1[k].x, hh, c1[k].y), V.call(c2[n].x, hh + 2.5, c2[n].y)])
		hh += 2.5
	var arms = [Vector2(15, 5), Vector2(19, 3.4)]
	for a in arms:
		segs.append([V.call(-a.y, a.x, 0), V.call(a.y, a.x, 0)])
		segs.append([V.call(-a.y, a.x, 0), V.call(-0.6, a.x + 1.4, 0)]); segs.append([V.call(a.y, a.x, 0), V.call(0.6, a.x + 1.4, 0)])
	Mk.lattice(world, segs, Mk.lam(0x6a6e70), 0.07)
	var pts = []
	for a in arms:
		for ax in [-a.y, a.y]:
			Mk.mi(world, Mk.CYL, Mk.lam(0x2a2a2a), Vector3(x + ax, y + a.x - 0.7, z), Vector3(0.09, 1.4, 0.09))
			for k in 4:
				Mk.mi(world, Mk.CYL, Mk.lam(0x4a5a60), Vector3(x + ax, y + a.x - 0.25 - k * 0.32, z), Vector3(0.2, 0.06, 0.2))
			pts.append(Vector3(x + ax, y + a.x - 1.4, z))
	circles.append(Vector3(x, z, 1.9))
	return pts

func power_line(list: Array) -> void:
	var prev = null; var arr = PackedVector3Array()
	for p in list:
		var pts = pylon(p.x, p.y)
		if prev != null:
			for i in pts.size():
				for q in 12:
					var t1 = q / 12.0; var t2 = (q + 1) / 12.0
					arr.append(prev[i].lerp(pts[i], t1) - Vector3(0, sin(PI * t1) * 2.2, 0))
					arr.append(prev[i].lerp(pts[i], t2) - Vector3(0, sin(PI * t2) * 2.2, 0))
		prev = pts
	Mk.lines(world, arr, C(0x1e1e1e))

func plant_fence() -> void:
	var Z = -7.0; var post = Mk.lam(0x8a877f); var wire = PackedVector3Array()
	var cx = -54.0
	while cx <= 54.0:
		if absf(cx) >= 4.0:
			var y = h(cx, Z)
			B(world, fence_mat, cx, y + 1.3, Z, 4, 2.6, 0.25); B(world, post, cx + 2, y + 1.6, Z, 0.35, 3.2, 0.35)
			B(world, post, cx + 2, y + 3.45, Z + 0.3, 0.1, 0.9, 0.1).rotation.x = 0.6
			for q in 8:
				var x1 = cx - 2 + q * 0.5; var x2 = x1 + 0.5
				wire.append(Vector3(x1, y + 2.72 + (q % 2) * 0.22, Z)); wire.append(Vector3(x2, y + 2.72 + ((q + 1) % 2) * 0.22, Z))
				wire.append(Vector3(x1, y + 3.6, Z + 0.55 + (q % 2) * 0.18)); wire.append(Vector3(x2, y + 3.6, Z + 0.55 + ((q + 1) % 2) * 0.18))
		cx += 4.0
	Mk.lines(world, wire, C(0x2a2a2a))
	boxes.append(Rect2(-56, Z - 0.35, 52, 0.7)); boxes.append(Rect2(4, Z - 0.35, 52, 0.7))
	for gx in [-4.3, 4.3]:
		B(world, Mk.lam(0x9a968c), gx, h(gx, Z) + 1.6, Z, 0.6, 3.2, 0.6)
	var piv = Node3D.new(); piv.position = Vector3(-4.3, h(0, Z) + 1.3, Z + 0.5); piv.rotation.z = 1.15; world.add_child(piv)
	B(piv, boom_mat, 3.8, 0, 0, 7.6, 0.22, 0.22)
	var bx = 8.0; var bz = -3.6; var by = h(bx, bz)
	B(world, Mk.lam(0x7f9a86), bx, by + 1.3, bz, 2.4, 2.6, 2.4); B(world, Mk.lam(0x4a4a46), bx, by + 2.75, bz, 2.8, 0.3, 2.8)
	B(world, Mk.lam(0x1e2428), bx - 1.21, by + 1.7, bz, 0.05, 0.9, 1.6); add_box_col(bx, bz, 2.4, 2.4)

func make_clouds() -> void:
	var q = QuadMesh.new(); q.size = Vector2(1, 1)
	for k in 16:
		var a = k / 16.0 * TAU + randf() * 0.3; var r = 280.0 + randf() * 90.0
		var n = Mk.mi(clouds, q, cloud_mat, Vector3(cos(a) * r, 70 + randf() * 80, sin(a) * r), Vector3(210 + randf() * 140, 70 + randf() * 40, 1))
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func make_crane(x: float, z: float) -> Dictionary:
	var g = Node3D.new(); g.position = Vector3(x, h(x, z), z); world.add_child(g)
	var org = Mk.lam(0xc8581e); var yel = Mk.lam(0xd9a41e)
	var Hm = 38.0; var w = 0.8; var cs = [Vector2(-w, -w), Vector2(w, -w), Vector2(w, w), Vector2(-w, w)]
	var segs = []; var ysegs = []
	var yy = 0.0
	while yy < Hm:
		var arr: Array = ysegs if yy < 10 else segs
		for k in 4:
			var a: Vector2 = cs[k]; var b: Vector2 = cs[(k + 1) % 4]
			arr.append([Vector3(a.x, yy, a.y), Vector3(a.x, yy + 2, a.y)]); arr.append([Vector3(a.x, yy, a.y), Vector3(b.x, yy + 2, b.y)])
		yy += 2.0
	Mk.lattice(g, segs, org, 0.08); Mk.lattice(g, ysegs, yel, 0.08); B(g, Mk.lam(0x3a3a38), 0, 0.3, 0, 3.4, 0.6, 3.4)
	var top = Node3D.new(); top.position.y = Hm; g.add_child(top)
	B(top, org, 0, 0.4, 0, 2.6, 0.8, 2.6); B(top, org, 1.6, 1.3, 1.2, 1.8, 1.7, 1.6); B(top, Mk.lam(0x1e2428), 0.69, 1.4, 1.2, 0.05, 1, 1.3)
	var jl = 30.0; var ang = 0.42
	var J = func(t: float, oy: float, oz: float) -> Vector3: return Vector3(-cos(ang) * t, 0.9 + sin(ang) * t + oy, oz)
	var js = []; var t = 0.0
	while t < jl:
		var t2 = t + 1.5
		js.append([J.call(t, 0, -0.45), J.call(t2, 0, -0.45)]); js.append([J.call(t, 0, 0.45), J.call(t2, 0, 0.45)]); js.append([J.call(t, 0.8, 0), J.call(t2, 0.8, 0)])
		js.append([J.call(t, 0, -0.45), J.call(t2, 0.8, 0)]); js.append([J.call(t, 0, 0.45), J.call(t2, 0.8, 0)]); js.append([J.call(t, 0, -0.45), J.call(t2, 0, 0.45)])
		t = t2
	Mk.lattice(top, js, org, 0.06)
	B(top, org, 5, 0.9, 0, 8, 0.5, 1); B(top, Mk.lam(0x6a6a68), 8.5, 0.4, 0, 2, 1.8, 1.8); B(top, org, 0, 3.2, 0, 0.45, 5.2, 0.45)
	var hk: Vector3 = J.call(23, 0, 0)
	Mk.lines(top, PackedVector3Array([Vector3(0, 5.8, 0), J.call(jl, 0.8, 0), Vector3(0, 5.8, 0), Vector3(8.5, 1.2, 0), hk, hk - Vector3(0, 24, 0)]), C(0x1a1a1a))
	B(top, yel, hk.x, hk.y - 24.4, 0, 0.6, 0.8, 0.6)
	circles.append(Vector3(x, z, 1.6))
	return {"g": g, "top": top}

func horizon_pines(n: int, col: int) -> void:
	var xs = []
	for k in n:
		var x = 0.0; var z = 0.0
		while true:
			x = R(-150, 150); z = R(-150, 150)
			if not (x > PMIN.x - 8 and x < PMAX.x + 8 and z > PMIN.y - 8 and z < PMAX.y + 8) and Vector2(x + 40, z - 66).length() > 12:
				break
		xs.append(Transform3D(Basis(Vector3.UP, R(0, 6)).scaled(Vector3.ONE * R(0.7, 1.5)), Vector3(x, h(x, z) - 0.5, z)))
	var tiers = [[2.6, 4.5, 2.6], [2.0, 4.0, 5.2], [1.3, 3.4, 7.6]]
	for ti in tiers.size():
		var cone = CylinderMesh.new(); cone.top_radius = 0.0; cone.bottom_radius = tiers[ti][0]; cone.height = tiers[ti][1]; cone.radial_segments = 7; cone.rings = 1
		var mm = MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = cone; mm.instance_count = n
		for k in n:
			var t: Transform3D = xs[k]
			mm.set_instance_transform(k, Transform3D(t.basis, t.origin + t.basis * Vector3(0, tiers[ti][2], 0)))
		var node = MultiMeshInstance3D.new(); node.multimesh = mm
		node.material_override = pbr(Mk.c(col).lightened(0.06 * ti).to_rgba32() >> 8, 0.95); world.add_child(node)
	var trunk = CylinderMesh.new(); trunk.top_radius = 0.25; trunk.bottom_radius = 0.35; trunk.height = 2.4; trunk.radial_segments = 5
	var tm = MultiMesh.new(); tm.transform_format = MultiMesh.TRANSFORM_3D; tm.mesh = trunk; tm.instance_count = n
	for k in n:
		var t: Transform3D = xs[k]
		tm.set_instance_transform(k, Transform3D(t.basis, t.origin + t.basis * Vector3(0, 1.0, 0)))
	var tn = MultiMeshInstance3D.new(); tn.multimesh = tm; tn.material_override = Mk.lam(0x3a2e24); world.add_child(tn)

func grass(n: int, col: int) -> void:
	var blade = CylinderMesh.new(); blade.top_radius = 0.0; blade.bottom_radius = 0.06; blade.height = 0.6; blade.radial_segments = 3; blade.rings = 2
	var mm = MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = blade
	var count = n * 2 if hq else n
	mm.instance_count = count
	var base = C(col)
	for k in count:
		var x = R(PMIN.x, PMAX.x); var z = R(PMIN.y, PMAX.y); var s = R(0.6, 1.7)
		if z < -5 and z > -30 and x > -62 and x < 34:
			s *= 0.4
		var bs = Basis.from_euler(Vector3(R(-0.25, 0.25), R(0, 6), R(-0.25, 0.25))).scaled(Vector3(s, s * R(0.8, 1.4), s))
		mm.set_instance_transform(k, Transform3D(bs, Vector3(x, h(x, z) + 0.25 * s, z)))
		mm.set_instance_color(k, Color(R(0.75, 1.15), R(0.8, 1.15), R(0.7, 1.0)))
	var node = MultiMeshInstance3D.new(); node.multimesh = mm
	var gm = grass_mat.duplicate()
	gm.set_shader_parameter("base_col", Vector3(base.r * 0.45, base.g * 0.5, base.b * 0.4))
	gm.set_shader_parameter("tip_col", Vector3(minf(1.0, base.r * 1.25), minf(1.0, base.g * 1.2), base.b))
	node.material_override = gm
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(node)

# ============================================================ Block 4
func reactor_defs() -> Array:
	var D = []; var pw = 34.0 / 6.0
	for i in 6:
		D.append({"s": 0, "k": "panel", "size": Vector3(pw, 16, 1), "pos": Vector3(-17 + pw * (i + 0.5), 8, FRONT - 0.5)})
	for x in [-9, -3, 3, 9]:
		D.append({"s": 1, "k": "wall", "size": Vector3(6, 14, 1), "pos": Vector3(x, 23, -29.5)})
	for z in [-33.25, -41.75]:
		D.append({"s": 1, "k": "wall", "size": Vector3(1, 14, 8.5), "pos": Vector3(-11.5, 23, z)})
		D.append({"s": 1, "k": "wall", "size": Vector3(1, 14, 8.5), "pos": Vector3(11.5, 23, z)})
	for x in [-9, -3, 3, 9]:
		D.append({"s": 2, "k": "roof", "size": Vector3(6, 0.8, 17), "pos": Vector3(x, 30.4, -37.5)})
	D.append({"s": 2, "k": "house", "size": Vector3(5, 3, 4), "pos": Vector3(-5, 32.3, -41)})
	D.append({"s": 2, "k": "house", "size": Vector3(4, 2.5, 5), "pos": Vector3(6, 32.05, -34)})
	D.append({"s": 2, "k": "banner", "size": Vector3(13, 3.8, 0.2), "pos": Vector3(0, 11.5, FRONT + 0.1)})
	D.append({"s": 2, "k": "star", "size": Vector3.ONE, "pos": Vector3(-17, 73.4, -37)})
	return D

func make_stub(d: Dictionary) -> Node3D:
	var g = Node3D.new(); world.add_child(g)
	var s: Vector3 = d.size; var p: Vector3 = d.pos
	if d.k == "panel":
		var hb = R(2, 6.5)
		B(g, facade_mat, p.x + R(-0.3, 0.3), hb / 2.0, p.z, s.x * R(0.55, 0.95), hb, s.z).rotation.z = R(-0.06, 0.06)
		var ht = R(1.5, 4.5)
		B(g, facade_mat, p.x + R(-0.4, 0.4), 16 - ht / 2.0, p.z, s.x * R(0.4, 0.9), ht, s.z).rotation.z = R(-0.08, 0.08)
		for k in 5:
			B(g, Mk.lam(pick([0x7a766e, 0x5a5650, 0xa8a49a, 0x8e8a82])), p.x + R(-s.x / 2, s.x / 2), R(0.2, 0.9), p.z + R(0.8, 4), R(0.8, 2.2), R(0.5, 1.6), R(0.8, 2.2)).rotation = Vector3(R(0, 1), R(0, 3), R(0, 1))
	else:
		var along = s.x > s.z; var hb = R(2, 7)
		B(g, facade_mat, p.x, 16 + hb / 2.0, p.z, s.x * R(0.5, 0.9) if along else s.x, hb, s.z if along else s.z * R(0.5, 0.9))
		if rng.randf() < 0.7:
			B(g, facade_mat, p.x + (R(-1.5, 1.5) if along else R(-0.5, 0.5)), 16 + hb + 1.6, p.z + (R(-0.5, 0.5) if along else R(-2, 2)), 3.0 if along else 0.8, 4, 0.8 if along else 3.0).rotation = Vector3(R(-0.5, 0.5), R(-0.3, 0.3), R(-0.6, 0.6))
		for k in 3:
			Mk.cyl_between(g, Vector3(p.x + R(-2, 2), 16 + hb, p.z + R(-1, 1)), Vector3(p.x + R(-3, 3), 16 + hb + R(2, 6), p.z + R(-3, 3)), 0.1, Mk.lam(0x3a3430))
	return g

func build_stack(x: float, y0: float, z: float) -> void:
	var SH = 46.0; var top = y0 + SH
	var cm = CylinderMesh.new(); cm.top_radius = 2.2; cm.bottom_radius = 2.6; cm.height = SH; cm.radial_segments = 24
	Mk.mi(world, cm, stack_mat, Vector3(x, y0 + SH / 2.0, z))
	Mk.mi(world, Mk.CYL, Mk.lam(0x2a2826), Vector3(x, top + 0.3, z), Vector3(2.45, 0.6, 2.45))
	var lv = []
	for k in 6:
		lv.append(y0 + k * SH / 5.0)
	var pt = func(k: int, y: float) -> Vector3:
		var a = k * PI / 4.0 + PI / 8.0; var r = lerpf(5.6, 3.5, (y - y0) / SH)
		return Vector3(x + cos(a) * r, y, z + sin(a) * r)
	var segs = []
	for i in 5:
		for k in 8:
			segs.append([pt.call(k, lv[i]), pt.call(k, lv[i + 1])]); segs.append([pt.call(k, lv[i]), pt.call(k + 1, lv[i + 1])]); segs.append([pt.call(k + 1, lv[i]), pt.call(k, lv[i + 1])])
	for i in range(1, 6):
		for k in 8:
			var p: Vector3 = pt.call(k, lv[i])
			segs.append([p, Vector3(x + (p.x - x) * 0.42, lv[i], z + (p.z - z) * 0.42)])
	Mk.lattice(world, segs, Mk.lam(0x9aa0a4), 0.13)
	for i in range(1, 6):
		var r = lerpf(5.6, 3.5, (lv[i] - y0) / SH)
		var t = TorusMesh.new(); t.inner_radius = r - 0.3; t.outer_radius = r + 0.3; t.rings = 8; t.ring_segments = 3
		Mk.mi(world, t, Mk.lam(0x6a6e70), Vector3(x, lv[i], z)).rotation.y = PI / 8
		var gm = Mk.lam(0x55595c).duplicate(); gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		Mk.mi(world, Mk.disc_mesh(r, 2.4, 8), gm, Vector3(x, lv[i] - 0.08, z)).rotation.y = -PI / 8
	var bm = Mk.glow(C(0xff2a1a), false)
	for k in 4:
		var a = k * PI / 2.0
		blinkers.append(Mk.mi(world, Mk.SPH, bm, Vector3(x + cos(a) * 3.6, lv[5] + 0.6, z + sin(a) * 3.6), Vector3.ONE * 0.35))

func build_reactor(stage: int) -> void:
	pieces = []; blinkers = []
	var roof = Mk.lam(0x4a4844); var dark = Mk.lam(0x161412); var steel = Mk.lam(0x3a3430)
	# Block 4 lower block; the 6 front panels are the level 1 pieces
	B(world, facade_mat, 0, 8, -37.5, 34, 16, 25)
	B(world, dark, 0, 7.9, FRONT - 0.9, 33.8, 15.8, 0.1)
	B(world, roof, 0, 16.15, -37.5, 34.4, 0.3, 26.2)
	# reactor hall: standing back wall with broken top
	B(world, facade_mat, 0, 20.5, -45.5, 24, 9, 1)
	for k in 7:
		var hh = R(2, 7)
		B(world, facade_mat, -10.5 + k * 3.5, 25 + hh / 2.0, -45.5, R(2, 3.6), hh, 1).rotation.z = R(-0.12, 0.12)
	B(world, Mk.lam(0x2a2622), 0, 16.45, -37.5, 22, 0.3, 16)
	for k in 18:
		var a = Vector3(R(-10, 10), 16.6, R(-44, -31))
		Mk.cyl_between(world, a, a + Vector3(R(-4, 4), R(3, 12), R(-3, 3)), R(0.1, 0.22), steel)
	for k in 26:
		B(world, Mk.lam(pick([0x5a5650, 0x6e6a62, 0x3e3a36, 0x7d786e])), R(-10, 10), 16.7 + R(0, 1.6), R(-44, -31), R(1, 3.5), R(0.6, 2.4), R(1, 3)).rotation = Vector3(R(-0.5, 0.5), R(0, 3), R(-0.5, 0.5))
	var gq = QuadMesh.new(); gq.size = Vector2(28, 14)
	var gm = Mk.glow(C(0xff7a30, 0.4), true, glow_tex); gm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	core_glow = Mk.mi(world, gq, gm, Vector3(0, 19, -37.5)); core_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core_light = OmniLight3D.new(); core_light.light_color = C(0xff8a40); core_light.omni_range = 48; core_light.position = Vector3(0, 21, -37.5); world.add_child(core_light)
	# stack block between Block 3 and 4, with the striped ventilation stack in its lattice frame
	B(world, facade_mat, -17, 20, -37, 10, 8, 14); B(world, roof, -17, 24.15, -37, 10.4, 0.3, 14.4)
	build_stack(-17, 24.3, -37)
	# Block 3 (intact)
	B(world, facade_mat, -39.5, 8, -37.5, 44, 16, 26); B(world, roof, -39.5, 16.15, -37.5, 44.4, 0.3, 26.4)
	B(world, facade_mat, -40, 23, -37.5, 24, 14, 17); B(world, roof, -40, 30.25, -37.5, 24.4, 0.5, 17.4)
	B(world, Mk.lam(0x9a968e), -46, 32, -40, 5, 3, 4); B(world, Mk.lam(0x9a968e), -34, 31.8, -34, 4, 2.5, 5)
	# stair tower, side block, pipe gallery
	B(world, facade2_mat, 20, 15, -29, 6, 30, 10); B(world, roof, 20, 30.2, -29, 6.3, 0.4, 10.3)
	var yy = 2.5
	while yy < 29:
		B(world, dark, 20, yy, -23.94, 1.4, 1.1, 0.1); yy += 2.4
	B(world, facade_mat, 21, 6, -44, 8, 12, 12); B(world, roof, 21, 12.15, -44, 8.3, 0.3, 12.3)
	var pg = Mk.lam(0x8a867e); B(world, pg, -6, 17.6, -49, 56, 2.4, 3)
	for px in range(-30, 20, 6):
		B(world, pg, px, 16.9, -49, 0.6, 1, 0.6)
	# long turbine hall behind
	B(world, facade2_mat, -10, 7, -63, 140, 14, 22); B(world, roof, -10, 14.2, -63, 140.4, 0.4, 22.4)
	for px in range(-76, 60, 12):
		B(world, Mk.lam(0x8a8780), px, 15.2, -63, 1.2, 1.6, 20)
	var plinth = Mk.lam(0x4e4b46)
	B(world, plinth, -20, 0.45, FRONT + 0.06, 86, 0.9, 0.12); B(world, plinth, -10, 0.45, -51.95, 140, 0.9, 0.12)
	B(world, plinth, 20, 0.45, -23.92, 6.1, 0.9, 0.1)
	var rib = Mk.lam(0xb7b4ab)
	for rx in range(-50, -28, 3):
		B(world, rib, rx, 23, -28.85, 0.35, 14, 0.3)
	for rx in range(-76, 60, 6):
		B(world, rib, rx, 7, -51.85, 0.4, 14, 0.3)
	var vent = Mk.lam(0x8c8982); var dk = Mk.lam(0x3a3836)
	for vx in [-52.0, -44.0, -30.0, -24.0, 8.0, 14.0]:
		B(world, vent, vx, 17.0, -34.0 if vx < -20 else -44.0, 1.6, 1.4, 1.6); B(world, dk, vx, 17.75, -34.0 if vx < -20 else -44.0, 1.8, 0.12, 1.8)
	for vx in range(-70, 55, 15):
		B(world, vent, vx + 4.0, 15.2, -58.0, 2.0, 1.6, 2.0); Mk.mi(world, Mk.CYL, dk, Vector3(vx + 4.0, 16.4, -58.0), Vector3(0.5, 0.9, 0.5))
	boxes.append(Rect2(-62, -76, 85.4, 76 + FRONT + 0.15))
	# the pieces to rebuild
	for d in reactor_defs():
		if d.s > stage:
			continue
		var n: Node3D
		var s: Vector3 = d.size
		match d.k:
			"panel", "wall": n = B(world, facade_mat, 0, 0, 0, s.x, s.y, s.z)
			"roof": n = B(world, Mk.lam(0x5a5752), 0, 0, 0, s.x, s.y, s.z)
			"house": n = B(world, Mk.lam(0xa29e95), 0, 0, 0, s.x, s.y, s.z)
			"banner":
				n = Node3D.new(); world.add_child(n)
				B(n, Mk.lam(0xb3261e), 0, 0, 0, s.x, s.y, s.z)
				var l = Label3D.new(); l.text = "МИРНЫЙ АТОМ"; l.font_size = 150; l.pixel_size = 0.0095; l.modulate = C(0xe8c35a)
				l.outline_size = 0; l.position = Vector3(0, 0, 0.12); l.font = hud.head_font; n.add_child(l)
			_:
				n = Mk.mi(world, star_mesh, star_mat, Vector3.ZERO, Vector3.ONE * 2.6)
		n.position = d.pos
		var pc = {"d": d, "n": n, "target": d.pos, "stub": null, "queued": false}
		if d.s == stage:
			n.visible = false
			if d.k == "panel" or d.k == "wall":
				pc.stub = make_stub(d)
		pieces.append(pc)
	if stage == 0:
		for k in 7:
			rubble(R(-15, 15), R(-22, -20), 4, 1.0)
	# construction pad
	var pad = CylinderMesh.new(); pad.top_radius = PAD_R; pad.bottom_radius = PAD_R; pad.height = 0.12; pad.radial_segments = 32
	Mk.mi(world, pad, hazard_mat, Vector3(PAD.x, h(PAD.x, PAD.y) + 0.06, PAD.y))
	var inner = CylinderMesh.new(); inner.top_radius = PAD_R - 0.6; inner.bottom_radius = PAD_R - 0.6; inner.height = 0.14; inner.radial_segments = 32
	Mk.mi(world, inner, Mk.lam(0x6a5a3a), Vector3(PAD.x, h(PAD.x, PAD.y) + 0.07, PAD.y))
	var beam = CylinderMesh.new(); beam.top_radius = PAD_R - 0.4; beam.bottom_radius = PAD_R - 0.4; beam.height = 10; beam.cap_top = false; beam.cap_bottom = false
	pad_beam = Mk.mi(world, beam, Mk.glow(C(0xffc04a, 0.12)), Vector3(PAD.x, 5, PAD.y)); pad_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pad_star = Mk.mi(world, star_mesh, star_mat, Vector3(PAD.x, 1.6, PAD.y), Vector3.ONE * 0.6)
	crane = make_crane(28, -19)
	# smoke
	smoke = CPUParticles3D.new()
	smoke.amount = 200 if hq else 100; smoke.lifetime = 15.0; smoke.preprocess = 15.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; smoke.emission_box_extents = Vector3(6, 1.5, 5)
	smoke.direction = Vector3.UP; smoke.spread = 8; smoke.initial_velocity_min = 3.2; smoke.initial_velocity_max = 5.0
	smoke.gravity = Vector3(0.9, 0.0, -0.3); smoke.damping_min = 0.05; smoke.damping_max = 0.15
	smoke.angle_min = 0; smoke.angle_max = 360; smoke.angular_velocity_min = -10; smoke.angular_velocity_max = 10
	var sc = Curve.new(); sc.add_point(Vector2(0, 0.3)); sc.add_point(Vector2(1, 1)); smoke.scale_amount_curve = sc
	smoke.scale_amount_min = 1.0; smoke.scale_amount_max = 1.4
	var gr = Gradient.new()
	if stage == 2:
		gr.set_color(0, Color(0.9, 0.55, 0.32, 0)); gr.set_color(1, Color(0.38, 0.38, 0.42, 0))
		gr.add_point(0.08, Color(0.95, 0.58, 0.34, 1.0)); gr.add_point(0.55, Color(0.42, 0.4, 0.42, 0.75))
	else:
		gr.set_color(0, Color(0.26, 0.25, 0.24, 0)); gr.set_color(1, Color(0.66, 0.64, 0.6, 0))
		gr.add_point(0.06, Color(0.1, 0.095, 0.09, 1.0)); gr.add_point(0.5, Color(0.3, 0.29, 0.28, 0.85))
	smoke.color_ramp = gr
	var q = QuadMesh.new(); q.size = Vector2(24, 24)
	smoke_mat = StandardMaterial3D.new(); smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_mat.vertex_color_use_as_albedo = true; smoke_mat.albedo_texture = smoke_tex; smoke_mat.disable_receive_shadows = true; smoke_mat.disable_fog = false
	q.material = smoke_mat; smoke.mesh = q; smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smoke.position = Vector3(0, 22, -37.5); world.add_child(smoke)
	smoke_target = 1.0 - STAGE_START[stage] / TOTAL_PIECES * 0.92; smoke_level = smoke_target

func update_smoke(delta: float) -> void:
	smoke_level += (smoke_target - smoke_level) * minf(1.0, delta * 0.6)
	if smoke:
		smoke_mat.albedo_color = Color(1, 1, 1, clampf(maxf(0.3, smoke_level), 0.0, 1.0))
		smoke.emitting = smoke_target > 0.02
		smoke.speed_scale = 1.0
	var night = li == 2 and state != "won"
	if core_glow:
		(core_glow.material_override as StandardMaterial3D).albedo_color.a = smoke_level * (0.3 + 0.1 * sin(clock_t * 2.3)) * (1.6 if night else 1.0)
		core_light.light_energy = smoke_level * (2.4 if night else 0.9) * (0.85 + 0.15 * sin(clock_t * 5.3))
	var on = sin(clock_t * 3.0) > 0.0
	for b in blinkers:
		b.visible = on

# ============================================================ characters
func pbr(hex: int, rough: float = 0.6, metal: float = 0.0) -> StandardMaterial3D:
	var mt = StandardMaterial3D.new(); mt.albedo_color = C(hex); mt.roughness = rough; mt.metallic = metal
	return mt

func make_oleg() -> Dictionary:
	var root = Node3D.new(); var body = Node3D.new(); root.add_child(body)
	var suit = pbr(0x56633a, 0.48); var seam = pbr(0x3d4729, 0.6); var mask = pbr(0x3b4139, 0.4); var glove = pbr(0x22251e, 0.42)
	var lens = pbr(0x0c1416, 0.05, 0.5); lens.emission_enabled = true; lens.emission = C(0x2f5a44); lens.emission_energy_multiplier = 0.35
	var brass = pbr(0xc0973e, 0.28, 0.9); var metal = pbr(0x6d7466, 0.35, 0.75); var canvas = pbr(0x6e5b3a, 0.95); var leather = pbr(0x4a3420, 0.7)
	var shine = Mk.glow(Color(1, 1, 1, 0.9), false)
	# torso, hips, seams, belt
	Mk.mi(body, Mk.cap(0.33, 0.98), suit, Vector3(0, 1.36, 0), Vector3(1.05, 1, 0.78))
	Mk.mi(body, Mk.SPH, suit, Vector3(0, 1.0, 0), Vector3(0.31, 0.24, 0.25))
	B(body, seam, 0, 1.4, 0.255, 0.035, 0.62, 0.02)
	B(body, seam, 0.14, 1.56, 0.245, 0.15, 0.13, 0.03)
	B(body, seam, -0.14, 1.56, 0.245, 0.15, 0.13, 0.03)
	Mk.mi(body, Mk.CYL, leather, Vector3(0, 1.08, 0), Vector3(0.345, 0.07, 0.272))
	B(body, brass, 0, 1.08, 0.27, 0.09, 0.065, 0.02)
	# gas-mask bag on the left hip, straps over the shoulder
	Mk.cyl_between(body, Vector3(0.22, 1.72, 0.17), Vector3(-0.3, 1.08, 0.2), 0.028, canvas)
	Mk.cyl_between(body, Vector3(0.22, 1.72, -0.17), Vector3(-0.3, 1.08, -0.08), 0.028, canvas)
	Mk.mi(body, Mk.cap(0.13, 0.38), canvas, Vector3(-0.4, 1.02, 0.06), Vector3(1, 1, 0.72))
	B(body, pbr(0x5a4a2e, 0.95), -0.4, 1.17, 0.06, 0.26, 0.08, 0.2)
	Mk.mi(body, Mk.CYL, metal, Vector3(-0.4, 1.24, 0.07), Vector3(0.075, 0.08, 0.075))
	# neck and head: GP-5 style mask with a rubber hood
	Mk.mi(body, Mk.CYL, mask, Vector3(0, 1.84, 0), Vector3(0.14, 0.14, 0.14))
	var head = Node3D.new(); head.position = Vector3(0, 2.04, 0); body.add_child(head)
	Mk.mi(head, Mk.SPH, mask, Vector3(0, 0.02, -0.01), Vector3(0.27, 0.3, 0.28))
	Mk.mi(head, Mk.SPH, mask, Vector3(0, 0.22, -0.02), Vector3(0.21, 0.12, 0.21))
	Mk.mi(head, Mk.SPH, pbr(0x2f342e, 0.32), Vector3(0, -0.03, 0.11), Vector3(0.22, 0.22, 0.19))
	for s in [-1, 1]:
		var l = Mk.mi(head, Mk.CYL, lens, Vector3(s * 0.1, 0.05, 0.27), Vector3(0.085, 0.03, 0.085)); l.rotation = Vector3(PI / 2, s * 0.28, 0)
		var t = TorusMesh.new(); t.inner_radius = 0.074; t.outer_radius = 0.108; t.rings = 20; t.ring_segments = 8
		var rim = Mk.mi(head, t, brass, Vector3(s * 0.1, 0.05, 0.275)); rim.rotation = Vector3(PI / 2, s * 0.28, 0)
		Mk.mi(head, Mk.SPH, shine, Vector3(s * 0.1 - 0.025, 0.08, 0.3), Vector3.ONE * 0.014)
	Mk.mi(head, Mk.CYL, metal, Vector3(0, -0.17, 0.27), Vector3(0.07, 0.08, 0.07)).rotation.x = 1.25
	var vt = TorusMesh.new(); vt.inner_radius = 0.05; vt.outer_radius = 0.08; vt.rings = 16; vt.ring_segments = 6
	Mk.mi(head, vt, metal, Vector3(0, -0.2, 0.3)).rotation.x = 1.25
	# corrugated hose from the mask down to the filter in the bag
	var p0 = Vector3(0, 1.8, 0.32); var p1 = Vector3(0.1, 1.42, 0.46); var p2 = Vector3(-0.38, 1.27, 0.12)
	var ht = TorusMesh.new(); ht.inner_radius = 0.03; ht.outer_radius = 0.058; ht.rings = 10; ht.ring_segments = 5
	for i in 16:
		var u = (i + 0.5) / 16.0
		var pos = p0.lerp(p1, u).lerp(p1.lerp(p2, u), u)
		var tan = ((p1 - p0) * (1.0 - u) + (p2 - p1) * u).normalized()
		var hn = MeshInstance3D.new(); hn.mesh = ht; hn.material_override = glove
		hn.transform = Transform3D(Basis(Quaternion(Vector3.UP, tan)), pos); body.add_child(hn)
	# arms with elbows, rubber gloves
	var arms = []; var elbows = []
	for s in [-1, 1]:
		var ap = Node3D.new(); ap.position = Vector3(s * 0.43, 1.68, 0); body.add_child(ap)
		Mk.mi(ap, Mk.SPH, suit, Vector3.ZERO, Vector3.ONE * 0.135)
		Mk.mi(ap, Mk.cap(0.1, 0.46), suit, Vector3(0, -0.2, 0))
		var ep = Node3D.new(); ep.position = Vector3(0, -0.4, 0); ap.add_child(ep)
		Mk.mi(ep, Mk.cap(0.095, 0.42), suit, Vector3(0, -0.17, 0))
		Mk.mi(ep, Mk.CYL, seam, Vector3(0, -0.32, 0), Vector3(0.1, 0.045, 0.1))
		Mk.mi(ep, Mk.cap(0.085, 0.24), glove, Vector3(0, -0.43, 0.01), Vector3(1, 1, 0.82))
		Mk.mi(ep, Mk.cap(0.035, 0.12), glove, Vector3(s * -0.06, -0.39, 0.06)).rotation.z = s * 0.5
		arms.append(ap); elbows.append(ep)
	# legs with knees, rubber boots
	var legs = []; var knees = []
	for s in [-1, 1]:
		var lp = Node3D.new(); lp.position = Vector3(s * 0.16, 0.97, 0); body.add_child(lp)
		Mk.mi(lp, Mk.cap(0.135, 0.54), suit, Vector3(0, -0.22, 0))
		var kp = Node3D.new(); kp.position = Vector3(0, -0.45, 0); lp.add_child(kp)
		Mk.mi(kp, Mk.cap(0.125, 0.46), suit, Vector3(0, -0.18, 0))
		Mk.mi(kp, Mk.CYL, glove, Vector3(0, -0.32, 0), Vector3(0.128, 0.16, 0.128))
		Mk.mi(kp, Mk.cap(0.11, 0.38), glove, Vector3(0, -0.42, 0.07)).rotation.x = PI / 2
		B(kp, pbr(0x111110, 0.8), 0, -0.505, 0.07, 0.22, 0.035, 0.38)
		legs.append(lp); knees.append(kp)
	# ДП-5 dosimeter in the right hand
	var det = Node3D.new(); det.position = Vector3(0, -0.47, 0.03); det.rotation.x = 1.5; elbows[1].add_child(det)
	B(det, pbr(0x6f6d34, 0.55), 0, 0.02, 0.08, 0.17, 0.1, 0.24)
	B(det, pbr(0x4a4826, 0.6), 0, 0.075, -0.01, 0.14, 0.02, 0.05)
	var face = Mk.mi(det, Mk.CYL, pbr(0xece2bf, 0.5), Vector3(0, 0.073, 0.1), Vector3(0.055, 0.008, 0.055))
	B(det, pbr(0x1a1a1a, 0.5), 0.012, 0.079, 0.1, 0.045, 0.004, 0.006).rotation.y = 0.6
	Mk.cyl_between(det, Vector3(-0.09, 0.0, 0.0), Vector3(-0.1, -0.02, 0.36), 0.018, metal)
	Mk.mi(det, Mk.CYL, pbr(0x2a2a2a, 0.5), Vector3(-0.1, -0.02, 0.38), Vector3(0.03, 0.06, 0.03)).rotation.x = PI / 2
	var led_m = Mk.glow(C(0x8aff5a), false)
	Mk.mi(det, Mk.SPH, led_m, Vector3(0.06, 0.075, 0.17), Vector3.ONE * 0.018)
	return {"root": root, "body": body, "head": head, "legs": legs, "arms": arms, "knees": knees, "elbows": elbows, "led": led_m, "face": face}

func make_bike() -> Dictionary:
	var g = Node3D.new(); var fr = Mk.lam(0x2f6a6a); var blk = Mk.lam(0x1a1a1a)
	var chrome = StandardMaterial3D.new(); chrome.albedo_color = C(0xaaaaaa); chrome.metallic = 0.8; chrome.roughness = 0.3
	var wheels = []
	for z in [0.68, -0.68]:
		var w = Node3D.new(); w.position = Vector3(0, 0.45, z); w.rotation.z = PI / 2; g.add_child(w)
		var t = TorusMesh.new(); t.inner_radius = 0.38; t.outer_radius = 0.46; t.rings = 24; t.ring_segments = 6
		Mk.mi(w, t, blk, Vector3.ZERO)
		for k in 4:
			B(w, chrome, 0, 0, 0, 0.8, 0.02, 0.02).rotation.y = k * PI / 4
		wheels.append(w)
	Mk.cyl_between(g, Vector3(0, 0.45, -0.68), Vector3(0, 0.95, -0.1), 0.035, fr); Mk.cyl_between(g, Vector3(0, 0.45, -0.68), Vector3(0, 0.5, 0), 0.035, fr)
	Mk.cyl_between(g, Vector3(0, 0.5, 0), Vector3(0, 0.95, -0.1), 0.035, fr); Mk.cyl_between(g, Vector3(0, 0.95, -0.1), Vector3(0, 1.0, 0.5), 0.035, fr)
	Mk.cyl_between(g, Vector3(0, 0.5, 0), Vector3(0, 1.0, 0.5), 0.035, fr); Mk.cyl_between(g, Vector3(0, 0.45, 0.68), Vector3(0, 1.12, 0.48), 0.035, chrome)
	B(g, blk, 0, 1.02, -0.15, 0.18, 0.06, 0.3); B(g, chrome, 0, 1.15, 0.48, 0.6, 0.04, 0.04); B(g, Mk.lam(0x8a6a3a), 0, 0.75, -0.6, 0.3, 0.04, 0.4)
	return {"g": g, "wheels": wheels}

func make_guard() -> Dictionary:
	var g = Node3D.new(); var body = Node3D.new(); g.add_child(body)
	var coat = pbr(0x4d5640, 0.85); var coat_d = pbr(0x3b4231, 0.85); var skin = pbr(0xe2b28c, 0.6); var fur = pbr(0x5b4330, 1.0)
	var boot = pbr(0x18181a, 0.32); var brass = pbr(0xc49a3e, 0.3, 0.85); var trouser = pbr(0x2c2e2a, 0.9); var leather = pbr(0x3a2818, 0.6)
	var skirt = CylinderMesh.new(); skirt.top_radius = 0.34; skirt.bottom_radius = 0.5; skirt.height = 0.75; skirt.radial_segments = 16
	Mk.mi(body, skirt, coat, Vector3(0, 0.8, 0))
	Mk.mi(body, Mk.cap(0.34, 0.88), coat, Vector3(0, 1.44, 0), Vector3(1.05, 1, 0.8))
	for row in [-0.09, 0.09]:
		for k in 4:
			Mk.mi(body, Mk.SPH, brass, Vector3(row, 1.24 + k * 0.13, 0.265), Vector3.ONE * 0.024)
	Mk.mi(body, Mk.CYL, leather, Vector3(0, 1.14, 0), Vector3(0.36, 0.08, 0.29))
	B(body, brass, 0, 1.14, 0.29, 0.1, 0.07, 0.02)
	Mk.cyl_between(body, Vector3(0.26, 1.78, 0.18), Vector3(-0.28, 1.16, 0.24), 0.025, leather)
	for s in [-1, 1]:
		B(body, pbr(0x8a2a1e, 0.7), s * 0.33, 1.84, 0, 0.18, 0.04, 0.16)
		B(body, brass, s * 0.33, 1.865, 0, 0.18, 0.01, 0.03)
	Mk.mi(body, Mk.CYL, coat_d, Vector3(0, 1.86, 0), Vector3(0.2, 0.08, 0.2))
	var head = Node3D.new(); head.position = Vector3(0, 2.07, 0); body.add_child(head)
	Mk.mi(head, Mk.SPH, skin, Vector3.ZERO, Vector3(0.25, 0.27, 0.25))
	Mk.mi(head, Mk.SPH, skin, Vector3(0, -0.02, 0.245), Vector3(0.05, 0.055, 0.05))
	Mk.mi(head, Mk.cap(0.032, 0.22), pbr(0x4a2e1a, 0.9), Vector3(0, -0.085, 0.225)).rotation.z = PI / 2
	for s in [-1, 1]:
		Mk.mi(head, Mk.SPH, pbr(0xf2eee4, 0.3), Vector3(s * 0.085, 0.04, 0.215), Vector3(0.035, 0.03, 0.02))
		Mk.mi(head, Mk.SPH, pbr(0x1a1a1a, 0.2), Vector3(s * 0.085, 0.04, 0.232), Vector3.ONE * 0.016)
		B(head, pbr(0x4a2e1a, 0.9), s * 0.085, 0.085, 0.225, 0.08, 0.018, 0.02).rotation.z = s * -0.15
		Mk.mi(head, Mk.cap(0.075, 0.28), fur, Vector3(s * 0.27, -0.02, 0), Vector3(1, 1, 1.3))
		Mk.mi(head, Mk.SPH, skin, Vector3(s * 0.245, 0.0, 0.02), Vector3(0.03, 0.05, 0.04))
	Mk.mi(head, Mk.SPH, fur, Vector3(0, 0.17, 0), Vector3(0.29, 0.17, 0.3))
	Mk.mi(head, Mk.CYL, fur, Vector3(0, 0.1, 0), Vector3(0.3, 0.1, 0.31))
	B(head, fur, 0, 0.21, 0.26, 0.42, 0.16, 0.07).rotation.x = -0.2
	Mk.mi(head, star_mesh, pbr(0xc0241a, 0.4), Vector3(0, 0.21, 0.3), Vector3.ONE * 0.06).rotation.x = -0.2
	var legs = []; var arms = []; var knees = []; var elbows = []
	for s in [-1, 1]:
		var lp = Node3D.new(); lp.position = Vector3(s * 0.15, 0.78, 0); body.add_child(lp)
		Mk.mi(lp, Mk.cap(0.105, 0.5), trouser, Vector3(0, -0.18, 0))
		var kp = Node3D.new(); kp.position = Vector3(0, -0.38, 0); lp.add_child(kp)
		Mk.mi(kp, Mk.cap(0.112, 0.42), boot, Vector3(0, -0.15, 0))
		Mk.mi(kp, Mk.cap(0.1, 0.32), boot, Vector3(0, -0.31, 0.06)).rotation.x = PI / 2
		legs.append(lp); knees.append(kp)
		var ap = Node3D.new(); ap.position = Vector3(s * 0.42, 1.74, 0); body.add_child(ap)
		Mk.mi(ap, Mk.SPH, coat, Vector3.ZERO, Vector3.ONE * 0.12)
		Mk.mi(ap, Mk.cap(0.095, 0.44), coat, Vector3(0, -0.19, 0))
		var ep = Node3D.new(); ep.position = Vector3(0, -0.38, 0); ap.add_child(ep)
		Mk.mi(ep, Mk.cap(0.09, 0.38), coat, Vector3(0, -0.15, 0))
		Mk.mi(ep, Mk.CYL, coat_d, Vector3(0, -0.29, 0), Vector3(0.1, 0.05, 0.1))
		Mk.mi(ep, Mk.SPH, skin, Vector3(0, -0.38, 0), Vector3(0.07, 0.08, 0.06))
		arms.append(ap); elbows.append(ep)
	var fl = Mk.mi(elbows[1], Mk.CYL, pbr(0x333333, 0.4, 0.6), Vector3(0, -0.4, 0.1), Vector3(0.045, 0.24, 0.045)); fl.rotation.x = PI / 2
	Mk.mi(elbows[1], Mk.SPH, Mk.glow(C(0xfff0a0), false), Vector3(0, -0.4, 0.23), Vector3.ONE * 0.05)
	if li == 2:
		var sp = SpotLight3D.new(); sp.light_color = C(0xfff0c0); sp.light_energy = 2.5; sp.spot_range = 11; sp.spot_angle = 24
		sp.position = Vector3(0.3, 1.4, 0.35); sp.rotation = Vector3(-0.45, PI, 0); g.add_child(sp)
	var cone_m = Mk.glow(C(0xfff0a0, 0.16))
	var cone = Mk.mi(g, Mk.sector_mesh(7.0, 0.5), cone_m, Vector3(0, 0.12, 0)); cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return {"g": g, "legs": legs, "arms": arms, "knees": knees, "elbows": elbows, "cone_m": cone_m, "VR": 7.0, "HA": 0.5}

# ============================================================ items / hazards
func mat_model(id: String) -> Node3D:
	var g = Node3D.new()
	match id:
		"concrete": B(g, conc_mat, 0, 0, 0, 0.9, 0.6, 0.9)
		"steel":
			var m = Mk.lam(0x9a5a30); B(g, m, 0, 0.22, 0, 1.4, 0.07, 0.45); B(g, m, 0, -0.22, 0, 1.4, 0.07, 0.45); B(g, m, 0, 0, 0, 1.4, 0.44, 0.07)
		"lead":
			B(g, Mk.lam(0x50555e), 0, 0, 0, 0.8, 0.35, 0.5)
			var q = QuadMesh.new(); q.size = Vector2(0.3, 0.36); var sm = StandardMaterial3D.new(); sm.albedo_texture = sign_tex
			Mk.mi(g, q, sm, Vector3(0, 0.18, 0)).rotation.x = -PI / 2
		_:
			for k in 3:
				B(g, Mk.lam(0x9a3a2a), 0, -0.2 + k * 0.2, 0, 0.75, 0.18, 0.36).rotation.y = k * 0.25
	return g

func add_item(x: float, z: float, type: Dictionary) -> void:
	var y = h(x, z); var grp = Node3D.new(); grp.position = Vector3(x, y, z); world.add_child(grp)
	var model = mat_model(type.id); model.position.y = 1; grp.add_child(model)
	var pm = PlaneMesh.new(); pm.size = Vector2(2.4, 2.4)
	Mk.mi(grp, pm, Mk.glow(C(type.c, 0.6), true, glow_tex), Vector3(0, 0.1, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm = CylinderMesh.new(); bm.top_radius = 0.25; bm.bottom_radius = 0.25; bm.height = 18; bm.cap_top = false; bm.cap_bottom = false; bm.radial_segments = 10
	Mk.mi(grp, bm, Mk.glow(C(type.c, 0.16)), Vector3(0, 9, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	items.append({"x": x, "z": z, "y": y, "type": type, "grp": grp, "model": model, "got": false, "ph": R(0, 6)})

func add_token(x: float, z: float) -> void:
	var y = h(x, z); var grp = Node3D.new(); grp.position = Vector3(x, y, z); world.add_child(grp)
	var sm = StandardMaterial3D.new(); sm.albedo_color = C(0xe0392b); sm.emission_enabled = true; sm.emission = C(0xff2a1a); sm.emission_energy_multiplier = 0.6
	var st = Mk.mi(grp, star_mesh, sm, Vector3(0, 1.2, 0), Vector3.ONE * 0.45)
	var q = QuadMesh.new(); q.size = Vector2(2, 2); var hm = Mk.glow(C(0xff5a3a, 0.6), true, glow_tex); hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	Mk.mi(grp, q, hm, Vector3(0, 1.2, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tokens.append({"x": x, "z": z, "y": y, "grp": grp, "st": st, "got": false})

func add_zone(x: float, z: float, r: float, s: float) -> void:
	var top = h(x, z)
	for a in 8:
		top = maxf(top, h(x + cos(a) * r, z + sin(a) * r))
	var pm = PlaneMesh.new(); pm.size = Vector2(r * 3, r * 3)
	var dm = Mk.glow(C(0x8aff3a if s > 1.3 else 0x7dff4a, 0.6), true, glow_tex)
	var disc = Mk.mi(world, pm, dm, Vector3(x, top + 0.12, z)); disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var rm = Mk.glow(C(0xc8ff6a, 0.45))
	var ring = Mk.mi(world, Mk.disc_mesh(r + 0.12, r - 0.12, 48), rm, Vector3(x, top + 0.15, z)); ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var p = CPUParticles3D.new(); p.amount = 40; p.lifetime = 4.0; p.preprocess = 4.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; p.emission_box_extents = Vector3(r * 0.7, 0.1, r * 0.7)
	p.direction = Vector3.UP; p.spread = 10; p.initial_velocity_min = 0.4; p.initial_velocity_max = 1.0; p.gravity = Vector3(0, 0.1, 0)
	var q = QuadMesh.new(); q.size = Vector2(0.5, 0.5); var qm = Mk.glow(C(0xaaff7a, 0.85), true, glow_tex); qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = qm; p.mesh = q; p.position = Vector3(x, top, z); p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(p)
	if s > 1.2:
		var rk = StandardMaterial3D.new(); rk.albedo_color = C(0x2a3a20); rk.emission_enabled = true; rk.emission = C(0x5aff2a); rk.emission_energy_multiplier = 0.9
		B(world, rk, x, top + 0.4, z, 1.1, 0.9, 1.0).rotation = Vector3(R(0, 3), R(0, 3), 0)
	var a2 = R(0, 6.28); rad_sign(x + cos(a2) * (r + 0.9), z + sin(a2) * (r + 0.9))
	zones.append({"x": x, "z": z, "r": r, "s": s, "dm": dm, "ring": ring, "ph": R(0, 6)})

func add_guard(cx: float, cz: float, r: float) -> void:
	var gd = make_guard(); world.add_child(gd.g)
	var a0 = R(0, 6.28); var wps = []
	for k in 4:
		var a = a0 + k * PI / 2.0
		wps.append(Vector2(clampf(cx + cos(a) * r, PMIN.x + 2, PMAX.x - 2), clampf(cz + sin(a) * r, PMIN.y + 2, PMAX.y - 2)))
	gd.merge({"x": wps[0].x, "z": wps[0].y, "wps": wps, "wi": 1, "face": 0.0, "pause": 0.0, "look": 0.0, "walk": 0.0, "spd": 1.9 + li * 0.35})
	guards.append(gd)

func add_trap(x: float, z: float) -> void:
	var y = h(x, z); var grp = Node3D.new(); grp.position = Vector3(x, y, z); world.add_child(grp)
	var rust = Mk.lam(0x5a4636); var conc = Mk.lam(0x77746c)
	for p in [Vector2(-2.2, -2.2), Vector2(2.2, -2.2), Vector2(-2.2, 2.2), Vector2(2.2, 2.2)]:
		B(grp, rust, p.x, 3.3, p.y, 0.3, 6.6, 0.3); circles.append(Vector3(x + p.x, z + p.y, 0.3))
	B(grp, rust, 0, 6.6, -2.2, 4.8, 0.35, 0.35); B(grp, rust, 0, 6.6, 2.2, 4.8, 0.35, 0.35); B(grp, rust, -2.2, 6.6, 0, 0.35, 0.35, 4.8); B(grp, rust, 2.2, 6.6, 0, 0.35, 0.35, 4.8)
	B(grp, conc, -1.6, 6.9, -1.4, 1.6, 0.25, 2).rotation.z = 0.1; B(grp, conc, 1.5, 6.9, 1.6, 2, 0.25, 1.4).rotation.x = -0.12
	var pm = PlaneMesh.new(); pm.size = Vector2(3.8, 3.8)
	var dm = StandardMaterial3D.new(); dm.albedo_texture = hazard_mat.albedo_texture
	Mk.mi(grp, pm, dm, Vector3(0, 0.08, 0))
	var panel = Node3D.new(); panel.position.y = 5.6; grp.add_child(panel)
	B(panel, conc_mat, 0, 0, 0, 3.2, 0.45, 3.2)
	var cp = PackedVector3Array()
	for c in [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5)]:
		cp.append(Vector3(c.x, 0.2, c.y)); cp.append(Vector3(c.x * 1.45, 1.0, c.y * 1.45))
	var cables = Mk.lines(panel, cp, C(0x222222))
	traps.append({"x": x, "z": z, "y": y, "panel": panel, "cables": cables, "st": "idle", "t": 0.0, "py": 5.6, "vy": 0.0})

# ============================================================ level loading
func load_level(i: int) -> void:
	if world:
		remove_child(world); world.queue_free()
	li = i; var L: Dictionary = LEVELS[i]; rng.seed = 1000 + i * 7919
	world = Node3D.new(); add_child(world)
	circles = []; boxes = []; reserved = []; items = []; tokens = []; zones = []; guards = []; debris = []; traps = []; lamps = []; queue = []; anims = []; pops = []
	built = 0; need = STAGE_COUNTS[i]; done_t = -1.0; debris_t = 3.0; level_t = 0.0; lost_level = 0; radio_done = {}; crane_pc = null; step_phase = 0
	sky_mat.sky_top_color = C(L.sky_top); sky_mat.sky_horizon_color = C(L.sky_hor)
	sky_mat.ground_horizon_color = C(L.fog); sky_mat.ground_bottom_color = C(L.fog).darkened(0.4)
	env.fog_light_color = C(L.fog); env.fog_depth_begin = L.fog_near; env.fog_depth_end = L.fog_far
	env.ambient_light_color = C(L.amb); env.ambient_light_energy = L.amb_e
	sun.light_color = C(L.sun); sun.light_energy = L.sun_e
	plight.light_energy = L.plight
	fill.light_color = C(0x7f94c8) if i == 2 else C(0x9fb4d8); fill.light_energy = 0.4 if i == 2 else 0.28
	cloud_mat.albedo_color = [C(0xf0ece4, 0.75), C(0xc0b0a8, 0.6), C(0x3a4252, 0.6)][i]
	make_terrain(L.ground)
	reserved.append(Vector3(START.x, START.y, 9)); reserved.append(Vector3(PAD.x, PAD.y, 6.5))
	reserved.append(Vector3(0, 14, 4)); reserved.append(Vector3(0, -2, 4))
	if i == 0:
		for p in PATH:
			reserved.append(Vector3(p.x, p.y, 4))
	build_reactor(i); plant_fence()
	if i == 0:
		reserved.append(Vector3(HERO.x, HERO.y, 3.5)); make_flag(HERO.x - 2.3, HERO.y + 0.9)
		var fdir = (Vector2(-4, -37) - HERO).normalized()
		for k in range(-3, 9):
			reserved.append(Vector3(HERO.x + fdir.x * k * 4.0, HERO.y + fdir.y * k * 4.0, 6.0))
	power_line([Vector2(38, 54), Vector2(38, 30), Vector2(38, 6), Vector2(38, -18), Vector2(38, -42)])
	if i == 0:
		cooling_tower(-95, -110); cooling_tower(-50, -125, 0.9); horizon_pines(240, 0x27301f); grass(1100, 0x6f7a3a)
		for k in 28:
			var s = spot(2)
			if s != null: birch(s.x, s.y)
		for k in 10:
			var s = spot(2)
			if s != null: dead_tree(s.x, s.y)
		for k in 2:
			var s = spot(5)
			if s != null: house(s.x, s.y)
		for k in 2:
			var s = spot(3)
			if s != null: car(s.x, s.y)
		for k in 4:
			var s = spot(2)
			if s != null: bale(s.x, s.y)
	elif i == 1:
		cooling_tower(-100, -95); horizon_pines(160, 0x1e231a); grass(400, 0x7a6e45)
		pripyat_landmarks()
		for k in 8:
			var w = R(8, 14); var d = R(6, 9); var hh = R(10, 22)
			var s = spot(maxf(w, d) / 2.0 + 2.0)
			if s != null: apt(s.x, s.y, w, d, hh)
		for k in 5:
			var s = spot(3)
			if s != null: car(s.x, s.y)
		for k in 14:
			var s = spot(2)
			if s != null: dead_tree(s.x, s.y)
		for k in 8:
			var s = spot(2.5)
			if s != null: rubble(s.x, s.y, 6, 1.4)
		for k in 7:
			var s = spot(1.5)
			if s != null: lamp_post(s.x, s.y, false)
	else:
		cooling_tower(-90, -100); cooling_tower(70, -110); horizon_pines(80, 0x151a14)
		lamp_post(-13, -20, true); lamp_post(12, -20, true)
		for pr in [[-40.0, 10.0, 22.0], [-48.0, -12.0, -2.0], [12.0, 48.0, 8.0]]:
			if is_free((pr[0] + pr[1]) / 2.0, pr[2], 0.5):
				pipe_run(pr[0], pr[2], pr[1])
		for k in 6:
			var rot = rng.randf() < 0.5; var s = spot(4.5)
			if s != null: container(s.x, s.y, rot)
		for k in 12:
			var s = spot(2)
			if s != null: barrier(s.x, s.y, rng.randf() < 0.5)
		for k in 10:
			var s = spot(2.5)
			if s != null: rubble(s.x, s.y, 6, 1.3)
		for k in 3:
			var s = spot(2)
			if s != null: lamp_post(s.x, s.y, true)
	# gameplay objects
	var mats = []
	for k in L.mats:
		var s = spot(1.6, func(x, z): return Vector2(x - START.x, z - START.y).length() > 10 and mats.all(func(m): return Vector2(x - m.x, z - m.y).length() > 11), 400)
		if s == null:
			s = spot(1.6, Callable(), 400)
		if s != null:
			mats.append(s); add_item(s.x, s.y, MATS[k % MATS.size()]); reserved.append(Vector3(s.x, s.y, 1.4))
	var t_count = 0
	for m in mats:
		if t_count >= ceili(L.traps / 2.0):
			break
		var ok = circles.all(func(c): return Vector2(m.x - c.x, m.y - c.y).length() > c.z + 3) and boxes.all(func(b): return not (m.x > b.position.x - 3 and m.x < b.end.x + 3 and m.y > b.position.y - 3 and m.y < b.end.y + 3))
		if ok:
			add_trap(m.x, m.y); reserved.append(Vector3(m.x, m.y, 3)); t_count += 1
	while t_count < L.traps:
		var s = spot(3.4, func(x, z): return Vector2(x - START.x, z - START.y).length() > 14)
		if s == null:
			break
		add_trap(s.x, s.y); reserved.append(Vector3(s.x, s.y, 3)); t_count += 1
	for k in L.zones:
		var r = R(3.5, 6.5) * (1.2 if k % 3 == 0 else 1.0)
		var s = spot(r + 1, func(x, z): return Vector2(x - START.x, z - START.y).length() > r + 12 and mats.all(func(m): return Vector2(x - m.x, z - m.y).length() > r + 1.8), 400)
		if s != null:
			add_zone(s.x, s.y, r, L.zone_s * (1.35 if k % 3 == 0 else 1.0)); reserved.append(Vector3(s.x, s.y, r + 0.5))
	for k in L.tokens:
		var s = spot(1.5, func(x, z): return Vector2(x - START.x, z - START.y).length() > 18)
		if s != null:
			add_token(s.x, s.y); reserved.append(Vector3(s.x, s.y, 1.5))
	for k in L.guards:
		var s = null; var r = 9.0
		for a in 4:
			var rr = r
			s = spot(r + 1, func(x, z): return Vector2(x - START.x, z - START.y).length() > rr + 14 and Vector2(x - PAD.x, z - PAD.y).length() > rr + 6, 300)
			if s != null:
				break
			r -= 2.0
		if s != null:
			add_guard(s.x, s.y, r)
	# floating dust
	dust = CPUParticles3D.new(); dust.amount = 260; dust.lifetime = 9.0; dust.preprocess = 9.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; dust.emission_box_extents = Vector3(25, 6, 25)
	dust.gravity = Vector3(0.35, 0.03, 0.05); dust.initial_velocity_min = 0.05; dust.initial_velocity_max = 0.2
	var q = QuadMesh.new(); q.size = Vector2.ONE * (0.14 if i == 2 else 0.09)
	var dm2 = Mk.glow(C(L.dust, 0.7 if i == 2 else 0.55), i == 2); dm2.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = dm2; dust.mesh = q; dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(dust)
	# weather: rain in Pripyat, snow on the night shift
	weather = null; sfx.set_rain(i == 1)
	if i >= 1:
		weather = CPUParticles3D.new(); weather.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; weather.local_coords = false
		var wq = QuadMesh.new(); var wm = Mk.glow(Color(0.75, 0.82, 0.9, 0.35) if i == 1 else Color(1, 1, 1, 0.85), false, glow_tex if i == 2 else null)
		wm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; wq.material = wm
		if i == 1:
			wq.size = Vector2(0.03, 0.7); weather.amount = 700 if hq else 350; weather.lifetime = 0.9; weather.emission_box_extents = Vector3(22, 1, 22)
			weather.direction = Vector3(0.1, -1, 0); weather.spread = 2; weather.initial_velocity_min = 20; weather.initial_velocity_max = 24; weather.gravity = Vector3.ZERO
		else:
			wq.size = Vector2(0.12, 0.12); weather.amount = 900 if hq else 450; weather.lifetime = 8.0; weather.emission_box_extents = Vector3(26, 1, 26)
			weather.direction = Vector3(0.2, -1, 0); weather.spread = 25; weather.initial_velocity_min = 1.0; weather.initial_velocity_max = 1.8; weather.gravity = Vector3(0.25, -0.15, 0)
		weather.preprocess = weather.lifetime; weather.mesh = wq; weather.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(weather)
	# crane mini-game helpers (level 3)
	crane_cable = ImmediateMesh.new(); var cm2 = StandardMaterial3D.new(); cm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; cm2.albedo_color = C(0x1a1a1a)
	var cn = MeshInstance3D.new(); cn.mesh = crane_cable; cn.material_override = cm2; cn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(cn)
	var ob = BoxMesh.new(); ob.size = Vector3(6.3, 1.0, 17.3)
	crane_outline = Mk.mi(world, ob, Mk.glow(C(0x7dff4a, 0.25)), Vector3.ZERO); crane_outline.visible = false; crane_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# player
	P.x = START.x; P.z = START.y; P.face = PI; P.inv = 1.5; P.carry = 0; P.dose = 0.0; P.cp = START; P.cheer = 0.0
	cam_yaw = 0.0; cam_pitch = 0.42; cam_dist = 10.0
	bike = make_bike(); world.add_child(bike.g)
	if i == 0:
		bike.g.visible = false
	else:
		var bx = START.x + 2.2; var bz = START.y + 1.0
		bike.g.position = Vector3(bx, h(bx, bz), bz); bike.g.rotation = Vector3(0, 0.6, 0.28); circles.append(Vector3(bx, bz, 0.7))
	hud.set_level("УРОВЕНЬ %d · %s\n%s" % [i + 1, L.ru, L.en])
	sfx.set_key(L.transpose)
	update_hud()

# ============================================================ flow
func _on_hud(id: String) -> void:
	match id:
		"start", "again": start_game()
		"continue": start_at(int(save.unlocked))
		"act": act_pressed()
		"help": hud.show_card("help")
		"back": hud.show_card("menu")
		"next": next_level()
		"retry": retry()
		"mute": toggle_mute()
		"quality": set_quality(not hq); save.hq = 1 if hq else 0; write_save()

func toggle_mute() -> void:
	muted = not muted; sfx.set_muted(muted); hud.set_mute_text(muted)
	if muted and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()

func set_quality(q: bool) -> void:
	hq = q; sun.shadow_enabled = hq
	get_viewport().msaa_3d = Viewport.MSAA_2X if hq else Viewport.MSAA_DISABLED
	get_viewport().scaling_3d_scale = 1.0 if hq else 0.75
	if smoke:
		smoke.amount = 200 if hq else 100
	hud.set_quality_text(hq)

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			save[k] = d[k]

func write_save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(save))

func total_stars() -> int:
	var t = 0
	for s in save.stars:
		t += int(s)
	return t

func update_menu_progress() -> void:
	var u = int(save.unlocked)
	var cont = ""
	if u > 0:
		cont = "ПРОДОЛЖИТЬ · CONTINUE: LEVEL %d" % (u + 1)
	var prog = ""
	if total_stars() > 0 or u > 0:
		prog = "Stars earned: %d / 9" % total_stars()
	hud.set_menu_progress(cont, prog)

func radio(key: String, ru: String, en: String, delay: float = 0.0) -> void:
	if radio_done.has(key):
		return
	radio_done[key] = true
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if state != "play" and state != "crane":
		return
	sfx.play("radio", -6.0); hud.radio(ru, en, 6.0)

func enter_menu() -> void:
	state = "menu"; menu_t = 0.0; sfx.music_on = false; hud.show_card("menu"); update_menu_progress()
	P.x = HERO.x; P.z = HERO.y; P.y = h(HERO.x, HERO.y); P.face = atan2(-4.0 - HERO.x, -37.0 - HERO.y); P.inv = 0.0; P.cheer = 0.0
	if march.stream:
		march.volume_db = -3.0; march.play()

func fade_march() -> void:
	if march.playing:
		var tw = create_tween(); tw.tween_property(march, "volume_db", -40.0, 1.6); tw.tween_callback(march.stop)

func start_at(i: int) -> void:
	if i <= 0:
		start_game(); return
	said = false; lives = 3; play_t = 0.0; sfx.music_on = true; sfx.step = 0
	fade_march(); hud.show_card(""); hud.fade(true); hud.show_fact(pick(LOAD_FACTS))
	await get_tree().create_timer(3.4).timeout
	load_level(i); state = "play"; hud.fade(false); hud.hide_fact(); hud.set_hud_visible(true); level_banner()

func start_game() -> void:
	said = false; lives = 3; play_t = 0.0; sfx.music_on = true; sfx.step = 0
	fade_march()
	hud.show_card(""); hud.fade(true)
	await get_tree().create_timer(0.6).timeout
	load_level(0); start_cutscene(); hud.fade(false)

func start_cutscene() -> void:
	state = "intro"; cut = {"t": 0.0, "stage": 0}; bike.g.visible = true
	hud.skip_l.visible = true; hud.set_hud_visible(false)
	hud.subs("Зона отчуждения. Тихое утро.", "The Exclusion Zone. A quiet morning.")

func end_cutscene() -> void:
	if state != "intro":
		return
	state = "play"; hud.skip_l.visible = false; hud.subs("", ""); hud.set_title_alpha(0.0)
	var bx = -4.2; var bz = 48.6
	bike.g.position = Vector3(bx, h(bx, bz), bz); bike.g.rotation = Vector3(0, 0.4, 0.3); circles.append(Vector3(bx, bz, 0.7))
	P.x = START.x; P.z = START.y; P.face = PI; cam_yaw = 0.0; reset_pose()
	hud.set_hud_visible(true); level_banner()

func level_banner() -> void:
	var L: Dictionary = LEVELS[li]
	match li:
		0: radio("start", "Олег, приём! Это пульт управления.", "Oleg, come in! This is the control room. Bring the materials to the yellow construction pad.", 10.0)
		1: radio("start", "Олег, в Припяти опасно. Смотри наверх!", "Oleg, Pripyat is dangerous. Watch out for junk falling from the roofs!", 10.0)
		_: radio("start", "Ночная смена, Олег. Последний рывок!", "Night shift, Oleg. One last push: the new roof over the reactor hall!", 10.0)
	hud.show_msg("УРОВЕНЬ %d: %s" % [li + 1, L.ru], L.en + " — " + L.tip_en, 5.0)
	await get_tree().create_timer(5.2).timeout
	if state == "play":
		hud.show_msg(L.tip_ru, L.tip_en, 4.0)

func next_level() -> void:
	hud.show_card(""); hud.fade(true); hud.show_fact(pick(LOAD_FACTS))
	await get_tree().create_timer(3.4).timeout
	hud.hide_fact()
	load_level(li + 1); state = "play"; hud.fade(false); hud.set_hud_visible(true); level_banner()

func retry() -> void:
	hud.show_card(""); lives = 3; hud.fade(true)
	await get_tree().create_timer(0.6).timeout
	load_level(li); state = "play"; hud.fade(false); hud.set_hud_visible(true); level_banner()

func update_hud() -> void:
	hud.set_stats(lives, P.carry, built, need)

func say(text: String, lang: String, pitch: float = 0.7, rate: float = 0.9) -> bool:
	if muted or not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return false
	var v = DisplayServer.tts_get_voices_for_language(lang)
	if v.is_empty():
		return false
	DisplayServer.tts_speak(text, v[0], 90, pitch, rate)
	return true

func hurt(kind: String) -> void:
	if P.inv > 0 or state != "play":
		return
	lives -= 1; lost_level += 1; var hh: Array = HURT[kind]; hud.show_msg(hh[0], hh[1], 2.4); hud.hit_flash()
	shake = 0.6
	if kind == "guard":
		sfx.play("whistle"); say("Стой!", "ru", 0.6, 1.0)
	else:
		sfx.play("hurt")
	burst(Vector3(P.x, P.y + 1, P.z), 20, [0x9dff6a, 0xffffff] if kind == "rad" else [0xe8c35a, 0x9a968c], 4, 0.8, 0.1)
	if lives <= 0:
		update_hud(); state = "over"; sfx.play("over")
		await get_tree().create_timer(0.9).timeout
		hud.show_card("over")
		return
	P.x = P.cp.x; P.z = P.cp.y; P.inv = 2.5; P.dose = 0.0; update_hud()

# ============================================================ effects
func burst(pos: Vector3, n: int, cols: Array, spd: float = 4.0, life: float = 1.0, size: float = 0.12, grav: float = 6.0) -> void:
	var p = CPUParticles3D.new(); p.one_shot = true; p.explosiveness = 1.0; p.amount = n; p.lifetime = life
	p.mesh = burst_mesh; p.direction = Vector3.UP; p.spread = 180; p.initial_velocity_min = spd * 0.4; p.initial_velocity_max = spd
	p.gravity = Vector3(0, -grav, 0); p.scale_amount_min = size * 1.2; p.scale_amount_max = size * 2.8; p.damping_min = 0.5; p.damping_max = 1.0
	var gi = Gradient.new()
	gi.set_color(0, C(cols[0])); gi.set_color(1, C(cols[cols.size() - 1]))
	if cols.size() > 2:
		gi.add_point(0.5, C(cols[1]))
	gi.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	p.color_initial_ramp = gi
	var gf = Gradient.new(); gf.set_color(0, Color(1, 1, 1, 1)); gf.set_color(1, Color(1, 1, 1, 0)); p.color_ramp = gf
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = pos; world.add_child(p); p.emitting = true
	p.finished.connect(p.queue_free)

func pop_text(pos: Vector3, ru: String, en: String, col: Color) -> void:
	var l = Label3D.new(); l.text = ru + ("\n" + en if en != "" else ""); l.font_size = 56; l.outline_size = 14
	l.modulate = col; l.outline_modulate = Color(0, 0, 0, 0.9); l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true; l.fixed_size = true; l.pixel_size = 0.0009; l.font = hud.head_font
	l.position = pos; world.add_child(l); pops.append({"n": l, "t": 0.0})

# ============================================================ input
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_M: toggle_mute()
			KEY_G: set_quality(not hq); save.hq = 1 if hq else 0; write_save(); aq.done = true
			KEY_P:
				if state == "play" or photo:
					photo = not photo; photo_t = 0.0; hud.set_hud_visible(not photo)
			KEY_SPACE, KEY_ENTER:
				act_pressed()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			if event.pressed and state == "intro":
				end_cutscene()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			cam_dist = clampf(cam_dist - 0.8, 6, 18)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			cam_dist = clampf(cam_dist + 0.8, 6, 18)
	elif event is InputEventMouseMotion and dragging:
		cam_yaw -= event.relative.x * 0.006; manual_cam = 2.0
		cam_pitch = clampf(cam_pitch + event.relative.y * 0.004, 0.15, 1.2)
	elif event is InputEventScreenDrag:
		cam_yaw -= event.relative.x * 0.006; manual_cam = 2.0

## Space / Enter / the touch OK button.
func act_pressed() -> void:
	if state == "crane": crane_lower()
	elif state == "menu" and hud.card_open("menu"): start_game()
	elif state == "menu" and hud.card_open("help"): hud.show_card("menu")
	elif state == "intro": end_cutscene()
	elif state == "levelDone" and hud.card_open("done"): next_level()
	elif state == "over" and hud.card_open("over"): retry()
	elif state == "won" and hud.card_open("win"): start_game()

func key(k: Key) -> bool:
	return Input.is_physical_key_pressed(k)

# ============================================================ update
func collide() -> void:
	var r = 0.5
	for c in circles:
		var dx: float = P.x - c.x; var dz: float = P.z - c.y; var d2 = dx * dx + dz * dz; var rr: float = r + c.z
		if d2 < rr * rr and d2 > 0.000001:
			var d = sqrt(d2); P.x = c.x + dx / d * rr; P.z = c.y + dz / d * rr
	for b in boxes:
		var cx = clampf(P.x, b.position.x, b.end.x); var cz = clampf(P.z, b.position.y, b.end.y)
		var dx: float = P.x - cx; var dz: float = P.z - cz; var d2 = dx * dx + dz * dz
		if d2 < r * r:
			if d2 > 0.00000001:
				var d = sqrt(d2); P.x = cx + dx / d * r; P.z = cz + dz / d * r
			else:
				var l: float = P.x - b.position.x; var rr: float = b.end.x - P.x; var f: float = P.z - b.position.y; var k: float = b.end.y - P.z
				var m: float = min(l, rr, f, k)
				if m == l: P.x = b.position.x - r
				elif m == rr: P.x = b.end.x + r
				elif m == f: P.z = b.position.y - r
				else: P.z = b.end.y + r
	P.x = clampf(P.x, PMIN.x, PMAX.x); P.z = clampf(P.z, PMIN.y, PMAX.y)

func reset_pose() -> void:
	for l in oleg.legs: l.rotation = Vector3.ZERO
	for a in oleg.arms: a.rotation = Vector3.ZERO
	for k in oleg.knees: k.rotation = Vector3.ZERO
	for e in oleg.elbows: e.rotation = Vector3.ZERO
	oleg.body.position.y = 0; oleg.body.rotation = Vector3.ZERO

func anim_oleg(delta: float, amt: float) -> void:
	var o = oleg
	o.root.position = Vector3(P.x, P.y, P.z); o.root.rotation.y = P.face
	var sw = sin(P.walk) * 0.65 * amt
	o.legs[0].rotation.x = sw; o.legs[1].rotation.x = -sw
	o.knees[0].rotation.x = 0.06 + maxf(0.0, sin(P.walk + 1.6)) * 0.95 * amt
	o.knees[1].rotation.x = 0.06 + maxf(0.0, sin(P.walk + 1.6 + PI)) * 0.95 * amt
	o.arms[0].rotation = Vector3(-sw * 0.8, 0, -0.08); o.elbows[0].rotation.x = -0.25 - maxf(0.0, -sin(P.walk)) * 0.35 * amt
	o.arms[1].rotation = Vector3(-0.55 + sin(P.walk) * 0.06 * amt, 0, 0.14); o.elbows[1].rotation.x = -0.95
	var breathe = sin(clock_t * 1.8) * 0.012 * (1.0 - amt)
	o.body.position.y = absf(sin(P.walk)) * 0.07 * amt + breathe; o.body.rotation.x = 0.07 * amt
	o.head.rotation = Vector3(-0.15 + sin(clock_t * 0.9) * 0.05 * (1.0 - amt), sin(clock_t * 0.7) * 0.3 * (1.0 - amt), 0)
	if P.cheer > 0:
		P.cheer -= delta
		o.arms[0].rotation = Vector3(-2.9, 0, -0.3); o.arms[1].rotation = Vector3(-2.9, 0, 0.3); o.elbows[0].rotation.x = -0.2; o.elbows[1].rotation.x = -0.2
		o.body.position.y = absf(sin(clock_t * 8)) * 0.25; o.head.rotation.x = -0.3
	o.led.albedo_color = C(0xff3b2a) if rad_rate > 0.6 else (C(0xffd23a) if rad_rate > 0.15 else C(0x8aff5a))
	o.root.visible = not (P.inv > 0 and int(clock_t * 10) % 2 == 1 and state == "play")

func _process(delta: float) -> void:
	raw_delta = delta
	delta = minf(delta, 0.05)
	clock_t += delta
	if state == "menu":
		ambient(delta); hero_menu(delta)
		return
	if state == "intro":
		update_cutscene(delta); ambient(delta)
		return
	var L: Dictionary = LEVELS[li]
	var fx = -sin(cam_yaw); var fz = -cos(cam_yaw); var rx = cos(cam_yaw); var rz = -sin(cam_yaw)
	if state == "crane":
		level_t += delta; update_crane(delta)
	if state == "play" and not photo:
		play_t += delta; level_t += delta
		var ix = (1.0 if key(KEY_D) or key(KEY_RIGHT) else 0.0) - (1.0 if key(KEY_A) or key(KEY_LEFT) else 0.0) + hud.joy.x
		var iz = (1.0 if key(KEY_W) or key(KEY_UP) else 0.0) - (1.0 if key(KEY_S) or key(KEY_DOWN) else 0.0) + hud.joy.y
		if key(KEY_Q): cam_yaw += 2.0 * delta; manual_cam = 2.0
		if key(KEY_E): cam_yaw -= 2.0 * delta; manual_cam = 2.0
		manual_cam = maxf(0.0, manual_cam - delta)
		var mx = fx * iz + rx * ix; var mz = fz * iz + rz * ix; var ml = Vector2(mx, mz).length()
		if ml > 1.0:
			mx /= ml; mz /= ml
		var run = key(KEY_SHIFT) or Input.is_action_pressed("touch_run"); var sp = 7.0 if run else 4.2
		P.moving = ml > 0.1
		if P.moving:
			P.x += mx * sp * delta; P.z += mz * sp * delta
			var d = atan2(mx, mz) - P.face; d = atan2(sin(d), cos(d)); P.face += d * minf(1.0, 12.0 * delta)
			P.walk += delta * (11.0 if run else 7.5)
			var sph = int(P.walk / PI)
			if sph != step_phase:
				step_phase = sph
				var hard = li == 2 or (P.z < -5 and P.z > -30) or (absf(P.x) < 3.2 and P.z > -6 and P.z < 34)
				sfx.play("step_hard" if hard else "step_soft", -8.0 if run else -11.0, randf_range(0.85, 1.15))
			# camera follows behind Oleg (no mouse needed); never swings round when walking backwards
			if manual_cam <= 0.0 and iz > -0.1:
				var dy = (P.face + PI) - cam_yaw; dy = atan2(sin(dy), cos(dy))
				var rate = (0.9 + 0.9 * maxf(0.0, iz)) * (1.25 if run else 1.0)
				cam_yaw += dy * minf(1.0, rate * delta)
		if manual_cam <= 0.0:
			cam_pitch = lerpf(cam_pitch, 0.42, minf(1.0, 0.8 * delta))
		collide(); P.y = h(P.x, P.z)
		if P.inv > 0: P.inv -= delta
		anim_oleg(delta, minf(1.0, ml) if P.moving else 0.0)
		# items
		for it in items:
			if it.got: continue
			if Vector2(P.x - it.x, P.z - it.z).length() < 1.6:
				it.got = true; it.grp.visible = false; P.carry += 1; sfx.play("pick")
				radio("pick", "Хорошо! Неси на стройку.", "Good work! Carry it to the construction site. The arrow at the top shows the way.")
				if items.all(func(q): return q.got):
					radio("all", "Всё собрано! Иди к стройке.", "That's everything! Head to the construction site.", 2.5)
				pop_text(Vector3(it.x, it.y + 2, it.z), "+1 " + it.type.ru, it.type.en, C(it.type.c))
				burst(Vector3(it.x, it.y + 1, it.z), 14, [0xffd27a, 0xffffff], 3, 0.7, 0.08); update_hud()
		for t in tokens:
			if t.got: continue
			if Vector2(P.x - t.x, P.z - t.z).length() < 1.6:
				t.got = true; t.grp.visible = false; lives = mini(lives + 1, 8); sfx.play("life")
				pop_text(Vector3(t.x, t.y + 2.2, t.z), "+1 ЖИЗНЬ", "Extra life!", C(0xff6a5a))
				burst(Vector3(t.x, t.y + 1.2, t.z), 18, [0xff4a3a, 0xffd27a], 4, 0.8, 0.09); update_hud()
		# deposit
		if P.carry > 0 and Vector2(P.x - PAD.x, P.z - PAD.y).length() < PAD_R:
			var rem = need - built - queue.size() - anims.size(); var n = mini(P.carry, rem)
			if n > 0:
				P.carry -= n
				var cur = pieces.filter(func(p): return p.d.s == li and not p.n.visible and not p.queued)
				for k in mini(n, cur.size()):
					cur[k].queued = true; queue.append(cur[k])
				sfx.play("deposit"); P.cp = Vector2(PAD.x, PAD.y + 1.5)
				radio("dep", "Отлично! Кран работает.", "Excellent! The crane is lifting your materials into place.", 1.5)
				pop_text(Vector3(PAD.x, 2.8, PAD.y), "Спасибо, товарищ!", "Thank you, comrade!", C(0xe8c35a)); update_hud()
		# radiation
		rad_rate = 0.0
		for z in zones:
			var d = Vector2(P.x - z.x, P.z - z.z).length()
			if d < z.r: rad_rate += z.s * (1.0 + (1.0 - d / z.r))
			elif d < z.r * 1.8: rad_rate += z.s * 0.3 * pow(1.0 - (d - z.r) / (z.r * 0.8), 2)
		if rad_rate > 0.45: P.dose += rad_rate * 20.0 * delta
		else: P.dose = maxf(0.0, P.dose - (2.0 if rad_rate > 0.05 else 7.0) * delta)
		if P.dose >= 100.0: hurt("rad")
		if P.dose > 45.0: radio("dose", "Олег, доза растёт! Уходи оттуда!", "Oleg, your dose is rising! Get out of the green glow!")
		if randf() < (0.6 + rad_rate * 35.0) * delta:
			sfx.play("click", -4.0, randf_range(0.8, 1.3)); hud.flash_led()
		# guards
		for g in guards:
			if g.pause > 0:
				g.pause -= delta; g.look += delta; g.face += sin(g.look * 2) * delta * 1.2; g.walk = 0.0
			else:
				var w: Vector2 = g.wps[g.wi]; var dx: float = w.x - g.x; var dz: float = w.y - g.z; var d = Vector2(dx, dz).length()
				if d < 0.3:
					g.wi = (g.wi + 1) % g.wps.size(); g.pause = 1.4; g.look = 0.0
				else:
					var s: float = g.spd * delta; g.x += dx / d * minf(s, d); g.z += dz / d * minf(s, d)
					var a: float = atan2(dx, dz) - g.face; a = atan2(sin(a), cos(a)); g.face += a * minf(1.0, 6.0 * delta); g.walk += delta * 7.0
			g.g.position = Vector3(g.x, h(g.x, g.z), g.z); g.g.rotation.y = g.face
			var sw: float = sin(g.walk) * 0.6 * (0.0 if g.pause > 0 else 1.0)
			g.legs[0].rotation.x = sw; g.legs[1].rotation.x = -sw; g.arms[0].rotation.x = -sw * 0.8; g.arms[1].rotation.x = -0.75
			g.knees[0].rotation.x = 0.05 + maxf(0.0, sin(g.walk + 1.6)) * 0.8 * absf(sw) / 0.6 if g.pause <= 0 else 0.05
			g.knees[1].rotation.x = 0.05 + maxf(0.0, sin(g.walk + 1.6 + PI)) * 0.8 * absf(sw) / 0.6 if g.pause <= 0 else 0.05
			g.elbows[0].rotation.x = -0.2; g.elbows[1].rotation.x = -0.75
			var px: float = P.x - g.x; var pz: float = P.z - g.z; var pd = Vector2(px, pz).length()
			var ang: float = atan2(px, pz) - g.face; ang = absf(atan2(sin(ang), cos(ang)))
			var seen: bool = (pd < g.VR and ang < g.HA) or pd < 1.2
			if pd < 13.0: radio("guard", "Осторожно, патруль рядом.", "Careful, a patrol is nearby. Stay out of the flashlight beam!")
			g.cone_m.albedo_color = C(0xff4a3a, 0.3) if seen else C(0xfff0a0, 0.16)
			if seen and P.inv <= 0 and state == "play":
				pop_text(Vector3(g.x, h(g.x, g.z) + 2.8, g.z), "СТОЙ!", "Halt!", C(0xff6a5a)); hurt("guard")
		# falling debris
		if L.debris:
			debris_t -= delta
			if debris_t <= 0:
				debris_t = R(L.gap[0], L.gap[1])
				for tr in 8:
					var lead = rng.randf() < 0.45
					var x: float = P.x + ((sin(P.face) * 3.0 if P.moving else 0.0) if lead else R(-11, 11))
					var z: float = P.z + ((cos(P.face) * 3.0 if P.moving else 0.0) if lead else R(-11, 11))
					if x < PMIN.x or x > PMAX.x or z < PMIN.y or z > PMAX.y or Vector2(x - PAD.x, z - PAD.y).length() < PAD_R + 1.5 or Vector2(x - START.x, z - START.y).length() < 5:
						continue
					if boxes.any(func(b): return x > b.position.x - 1 and x < b.end.x + 1 and z > b.position.y - 1 and z < b.end.y + 1):
						continue
					spawn_debris(x, z); break
		update_debris(delta); update_traps(delta)
		# compass
		var left = items.filter(func(i): return not i.got)
		var tx = PAD.x; var tz = PAD.y; var lbl = "Стройка · Construction site"; var ccol = C(0xd9a441); var cicon = "site"
		var remaining = need - built - queue.size() - anims.size()
		if not (P.carry > 0 and (left.is_empty() or P.carry >= remaining)) and not left.is_empty():
			var best = null; var bd = 1e9
			for it in left:
				var d = Vector2(it.x - P.x, it.z - P.z).length()
				if d < bd: bd = d; best = it
			tx = best.x; tz = best.z; lbl = "%s · %s (%d м)" % [best.type.ru, best.type.en, int(bd)]; ccol = C(best.type.c); cicon = best.type.id
			if P.carry > 0: lbl += "  ·  or deliver to the site"
		var dx2 = tx - P.x; var dz2 = tz - P.z
		hud.set_compass(atan2(dx2 * rx + dz2 * rz, dx2 * fx + dz2 * fz), lbl, ccol, cicon)
		var v = 0.12 + rad_rate * 48.0
		hud.set_detector(v, rad_rate > 0.45, -70.0 + 140.0 * clampf(log(v / 0.1) / log(6000.0), 0.0, 1.0) + sin(clock_t * 30) * rad_rate * 2.0, P.dose, rad_rate)
	# building animation
	if not queue.is_empty() and state == "play":
		queue_t -= delta
		if queue_t <= 0:
			queue_t = 0.6; var pc: Dictionary = queue.pop_front()
			if pc.d.k == "roof":
				start_crane(pc)
			else:
				pc.n.visible = true; pc.n.position.y = pc.target.y + 22; anims.append({"pc": pc, "t": 0.0})
	for k in range(anims.size() - 1, -1, -1):
		var a: Dictionary = anims[k]; a.t += delta / 0.9; var e = minf(1.0, a.t)
		a.pc.n.position.y = a.pc.target.y + 22.0 * (1.0 - e * e)
		if a.t >= 1.0:
			anims.remove_at(k); land_piece(a.pc)
	if done_t > 0 and state == "play":
		done_t -= delta
		if done_t <= 0: level_complete()
	if state == "won": update_win(delta)
	if state == "levelDone" or state == "over" or state == "crane": anim_oleg(delta, 0)
	ambient(delta)
	if photo:
		photo_t += delta; var pa = 0.6 + photo_t * 0.12
		cam.position = Vector3(-6 + sin(pa) * 62, 26 + sin(photo_t * 0.2) * 8, -37 + cos(pa) * 62); cam.look_at(Vector3(-6, 22, -37))
	elif state == "crane" and crane_pc != null:
		var t3: Vector3 = crane_pc.target
		cam.position = cam.position.lerp(Vector3(t3.x + 2, t3.y + 34, t3.z + 30), minf(1.0, 2.5 * delta)); cam.look_at(Vector3(t3.x, t3.y, t3.z - 2))
	elif state != "won":
		var tgt = Vector3(P.x, P.y + 1.5, P.z)
		var want = tgt + Vector3(sin(cam_yaw) * cos(cam_pitch), sin(cam_pitch), cos(cam_yaw) * cos(cam_pitch)) * cam_dist
		want.y = maxf(want.y, h(want.x, want.z) + 1.0)
		cam.position = cam.position.lerp(want, minf(1.0, 8.0 * delta)); cam.look_at(tgt)
	if shake > 0:
		shake -= delta; cam.position += Vector3(randf() - 0.5, randf() - 0.5, 0) * shake * 0.8

func land_piece(pc: Dictionary) -> void:
	pc.n.position = pc.target; built += 1; sfx.play("thud"); shake = maxf(shake, 0.35)
	burst(pc.target, 22, [0x9a968c, 0xbab6ac, 0x7a766e], 5, 1.1, 0.22, 3)
	if pc.stub:
		burst(pc.target + Vector3(0, 0, 1), 20, [0x8a867e, 0xbab6ac], 6, 1.2, 0.25, 3)
		pc.stub.queue_free(); pc.stub = null
	smoke_target = 1.0 - (STAGE_START[li] + built) / TOTAL_PIECES * 0.92
	update_hud()
	if built >= need: done_t = 1.6

# ------------------------------------------------------------ crane mini-game (roof slabs, level 3)
func start_crane(pc: Dictionary) -> void:
	state = "crane"; crane_pc = pc; pc.n.visible = true
	var t: Vector3 = pc.target
	crane_hook = Vector2(t.x + R(-6, 6), t.z + 9.0); crane_vel = Vector2.ZERO; crane_sway = Vector2.ZERO
	crane_drop = -1.0; crane_y = t.y + 9.0; crane_slab_y = crane_y
	crane_outline.position = t; crane_outline.visible = true
	hud.set_act_text("DROP")
	hud.show_msg("КРАН!  ·  CRANE TIME!", "Steer the roof slab with WASD / arrows (or the joystick). Press SPACE to lower it onto the green outline.", 6.0)
	radio("crane", "Теперь ты на кране, Олег!", "You're on the crane now, Oleg! Line the slab up with the green outline, then lower it.", 0.5)

func crane_lower() -> void:
	if crane_pc != null and crane_drop < 0.0:
		crane_drop = 0.0; sfx.play("creak", -2.0, 0.8)

func update_crane(delta: float) -> void:
	if crane_pc == null:
		return
	var t: Vector3 = crane_pc.target
	if crane_drop < 0.0:
		var ix = (1.0 if key(KEY_D) or key(KEY_RIGHT) else 0.0) - (1.0 if key(KEY_A) or key(KEY_LEFT) else 0.0) + hud.joy.x
		var iz = (1.0 if key(KEY_W) or key(KEY_UP) else 0.0) - (1.0 if key(KEY_S) or key(KEY_DOWN) else 0.0) + hud.joy.y
		var want = Vector2(ix, -iz).limit_length(1.0) * 6.5
		var acc = (want - crane_vel) * minf(1.0, 3.5 * delta)
		crane_vel += acc
		crane_hook += crane_vel * delta
		crane_hook.x = clampf(crane_hook.x, t.x - 14, t.x + 14); crane_hook.y = clampf(crane_hook.y, t.z - 14, t.z + 16)
		crane_sway = crane_sway.lerp(-crane_vel * 0.14, minf(1.0, 1.6 * delta)) + Vector2(sin(clock_t * 2.1), cos(clock_t * 1.7)) * 0.004
		crane_slab_y = lerpf(crane_slab_y, crane_y, minf(1.0, 3.0 * delta))
		crane_creak -= delta
		if crane_vel.length() > 1.5 and crane_creak <= 0.0:
			crane_creak = 1.4; sfx.play("creak", -12.0, randf_range(0.8, 1.1))
	else:
		crane_drop += delta / 1.1
		crane_slab_y = lerpf(crane_y, t.y, minf(1.0, crane_drop * crane_drop))
		crane_sway = crane_sway.lerp(Vector2.ZERO, minf(1.0, 0.8 * delta))
	var sx = crane_hook.x + crane_sway.x; var sz = crane_hook.y + crane_sway.y
	crane_pc.n.position = Vector3(sx, crane_slab_y, sz)
	crane_outline.material_override.albedo_color.a = 0.18 + 0.12 * sin(clock_t * 5.0)
	if not crane.is_empty():
		var cg: Node3D = crane.g
		var cv = Vector2(crane_hook.x - cg.position.x, crane_hook.y - cg.position.z)
		var want_r = atan2(cv.y, -cv.x); var dr = want_r - crane.top.rotation.y; dr = atan2(sin(dr), cos(dr))
		crane.top.rotation.y += dr * minf(1.0, 3.0 * delta)
		crane_cable.clear_surfaces(); crane_cable.surface_begin(Mesh.PRIMITIVE_LINES)
		for o in [Vector2(-2.6, -7.5), Vector2(2.6, -7.5), Vector2(-2.6, 7.5), Vector2(2.6, 7.5)]:
			crane_cable.surface_add_vertex(Vector3(sx + o.x, crane_slab_y + 0.4, sz + o.y)); crane_cable.surface_add_vertex(Vector3(sx, crane_slab_y + 5.0, sz))
		crane_cable.surface_add_vertex(Vector3(sx, crane_slab_y + 5.0, sz)); crane_cable.surface_add_vertex(Vector3(sx, cg.position.y + 46.0, sz))
		crane_cable.surface_end()
	if crane_drop >= 1.0:
		var err = Vector2(sx - t.x, sz - t.z).length()
		if err < 1.2:
			var pc: Dictionary = crane_pc; crane_pc = null; crane_outline.visible = false; crane_cable.clear_surfaces()
			land_piece(pc); state = "play"; hud.set_act_text("OK")
			hud.show_msg("ОТЛИЧНО!  ·  PERFECT!", "The roof slab is in place.", 2.2)
		else:
			crane_drop = -1.0; sfx.play("thud", -6.0, 1.3); shake = maxf(shake, 0.2)
			hud.show_msg("МИМО!  ·  MISSED!", "Line the slab up with the green outline and try again.", 2.5)

# ------------------------------------------------------------ Pripyat landmarks (level 2)
func pripyat_landmarks() -> void:
	# School No. 3: a long three-storey school
	var sx = 28.0; var sz = 20.0
	B(world, facade2_mat, sx, h(sx, sz) + 5.0, sz, 24, 10, 9); B(world, Mk.lam(0x4a4844), sx, h(sx, sz) + 10.15, sz, 24.4, 0.3, 9.4)
	B(world, facade_mat, sx, h(sx, sz) + 6.0, sz + 5.2, 6, 12, 2); B(world, Mk.lam(0x1e2428), sx, h(sx, sz) + 1.4, sz + 6.25, 2.4, 2.8, 0.1)
	var sl = Label3D.new(); sl.text = "ШКОЛА № 3\nSCHOOL No. 3"; sl.font_size = 96; sl.pixel_size = 0.012; sl.modulate = C(0x2a2a2a); sl.outline_size = 0
	sl.font = hud.head_font; sl.position = Vector3(sx, h(sx, sz) + 9.2, sz + 6.26); world.add_child(sl)
	for k in 6:
		B(world, Mk.lam(pick([0x7a766e, 0x5a5650])), sx + R(-10, 10), h(sx, sz) + 0.3, sz + R(5, 8), R(0.5, 1.2), R(0.3, 0.8), R(0.5, 1.2)).rotation.y = R(0, 3)
	add_box_col(sx, sz, 24, 9); add_box_col(sx, sz + 5.2, 6, 2); reserved.append(Vector3(sx, sz + 8.0, 4.0))
	# Hotel Polesie with the big letters on the roof
	var hx = -38.0; var hz = 16.0; var hy = h(hx, hz)
	B(world, facade2_mat, hx, hy + 11.0, hz, 18, 22, 10); B(world, Mk.lam(0x4a4844), hx, hy + 22.15, hz, 18.4, 0.3, 10.4)
	for k in 4:
		B(world, Mk.lam(0x5a5c5e), hx - 6 + k * 4, hy + 23.2, hz + 4.5, 0.12, 2.0, 0.12)
	var hl = Label3D.new(); hl.text = "ПОЛІССЯ"; hl.font_size = 220; hl.pixel_size = 0.016; hl.modulate = C(0xc8322a); hl.outline_size = 0
	hl.font = hud.head_font; hl.position = Vector3(hx, hy + 24.3, hz + 4.6); world.add_child(hl)
	var hl2 = Label3D.new(); hl2.text = "HOTEL POLESIE"; hl2.font_size = 80; hl2.pixel_size = 0.012; hl2.modulate = C(0x2a2a2a); hl2.outline_size = 0
	hl2.font = hud.head_font; hl2.position = Vector3(hx, hy + 3.4, hz + 5.06); world.add_child(hl2)
	add_box_col(hx, hz, 18, 10)
	# the amusement park you can walk through: Ferris wheel and bumper cars
	var fx2 = -34.0; var fz2 = 42.0
	var g = Node3D.new(); g.position = Vector3(fx2, h(fx2, fz2), fz2); g.rotation.y = 0.25; world.add_child(g)
	var yel = pbr(0xc9a227, 0.55, 0.3); var rust = Mk.lam(0x6a5a3a)
	for s in [-1, 1]:
		var tm = TorusMesh.new(); tm.inner_radius = 10.8; tm.outer_radius = 11.2; tm.rings = 48; tm.ring_segments = 6
		Mk.mi(g, tm, yel, Vector3(0, 13, s)).rotation.x = PI / 2
		Mk.cyl_between(g, Vector3(-6, 0, s * 2.5), Vector3(0, 13, s), 0.3, rust); Mk.cyl_between(g, Vector3(6, 0, s * 2.5), Vector3(0, 13, s), 0.3, rust)
	Mk.cyl_between(g, Vector3(0, 13, -1.2), Vector3(0, 13, 1.2), 0.5, rust)
	for k in 12:
		var a = k / 12.0 * TAU; var p = Vector3(cos(a) * 11, 13 + sin(a) * 11, 0)
		Mk.cyl_between(g, Vector3(0, 13, 0), p, 0.08, yel)
		var cab = Node3D.new(); cab.position = p - Vector3(0, 1.1, 0); g.add_child(cab)
		B(cab, pbr(0xd9b43a, 0.6), 0, 0, 0, 1.4, 0.9, 1.4); B(cab, pbr(0xc0392b, 0.6), 0, 0.7, 0, 1.6, 0.15, 1.6)
	var bs = Basis(Vector3.UP, 0.25)
	for lp in [Vector3(-6, 0, -2.5), Vector3(6, 0, -2.5), Vector3(-6, 0, 2.5), Vector3(6, 0, 2.5)]:
		var w = g.position + bs * lp; circles.append(Vector3(w.x, w.z, 0.5))
	reserved.append(Vector3(fx2, fz2, 8.0))
	var bx2 = -16.0; var bz2 = 33.0; var by2 = h(bx2, bz2)
	B(world, Mk.lam(0x2a2a2c), bx2, by2 + 0.1, bz2, 12, 0.2, 9)
	B(world, pbr(0x3f6f8a, 0.7), bx2, by2 + 4.2, bz2, 12.6, 0.35, 9.6)
	for p in [Vector2(-6, -4.5), Vector2(6, -4.5), Vector2(-6, 4.5), Vector2(6, 4.5), Vector2(0, -4.5), Vector2(0, 4.5)]:
		Mk.mi(world, Mk.CYL, rust, Vector3(bx2 + p.x, by2 + 2.1, bz2 + p.y), Vector3(0.12, 4.2, 0.12)); circles.append(Vector3(bx2 + p.x, bz2 + p.y, 0.25))
	for k in 6:
		var c = Node3D.new(); c.position = Vector3(bx2 + R(-4.5, 4.5), by2 + 0.45, bz2 + R(-3, 3)); c.rotation.y = R(0, 6); world.add_child(c)
		var col = pbr(pick([0xc0392b, 0x2e7dbf, 0xd9a41e, 0x3e9a4a]), 0.5, 0.2)
		Mk.mi(c, Mk.cap(0.6, 1.9), col, Vector3.ZERO, Vector3(1, 0.45, 1)).rotation.z = PI / 2
		Mk.mi(c, Mk.CYL, Mk.lam(0x1a1a1a), Vector3(0, -0.15, 0), Vector3(0.85, 0.12, 0.65))
		Mk.mi(c, Mk.CYL, Mk.lam(0x555555), Vector3(0.5, 1.6, 0), Vector3(0.03, 2.4, 0.03))
	var pl = Label3D.new(); pl.text = "ПАРК · PARK"; pl.font_size = 90; pl.pixel_size = 0.012; pl.modulate = C(0xf0c040); pl.font = hud.head_font
	pl.outline_size = 10; pl.position = Vector3(bx2, by2 + 4.9, bz2 + 4.9); world.add_child(pl)
	reserved.append(Vector3(bx2, bz2, 7.5))

func spawn_debris(x: float, z: float) -> void:
	var y = h(x, z)
	var ring = Mk.mi(world, Mk.disc_mesh(1.75, 1.5), Mk.glow(C(0xff3a2a, 0.8), false), Vector3(x, y + 0.15, z))
	var fill = Mk.mi(world, Mk.disc_mesh(1.5), Mk.glow(C(0xff3a2a, 0.25), false), Vector3(x, y + 0.13, z))
	var chunk = Node3D.new(); B(chunk, Mk.lam(pick([0x8a867e, 0x6e6a62, 0x7a5a3a])), 0, 0, 0, R(0.9, 1.4), R(0.7, 1.1), R(0.9, 1.4))
	if rng.randf() < 0.5: B(chunk, Mk.lam(0x5a4636), 0.3, 0.3, 0, 0.15, 1.6, 0.15)
	chunk.position = Vector3(x, y + 24, z); world.add_child(chunk)
	debris.append({"x": x, "z": z, "y": y, "t": 1.5, "max": 1.5, "ring": ring, "fill": fill, "chunk": chunk, "landed": false, "life": 3.0})

func update_debris(delta: float) -> void:
	for k in range(debris.size() - 1, -1, -1):
		var d: Dictionary = debris[k]
		if not d.landed:
			d.t -= delta; var k2: float = 1.0 - d.t / d.max
			d.fill.scale = Vector3.ONE * maxf(0.01, k2); d.ring.material_override.albedo_color.a = 0.5 + 0.4 * sin(clock_t * 20)
			d.chunk.position.y = d.y + 0.5 + 23.5 * pow(maxf(0.0, d.t / d.max), 2); d.chunk.rotation.x += delta * 3; d.chunk.rotation.z += delta * 2
			if d.t <= 0:
				d.landed = true; d.chunk.position.y = d.y + 0.5; d.ring.queue_free(); d.fill.queue_free(); sfx.play("thud", -3.0)
				burst(Vector3(d.x, d.y + 0.4, d.z), 16, [0x8a867e, 0xaaa69c], 4, 0.8, 0.18, 4)
				if Vector2(cam.position.x - d.x, cam.position.z - d.z).length() < 25: shake = maxf(shake, 0.3)
				if state == "play" and Vector2(P.x - d.x, P.z - d.z).length() < 1.7: hurt("debris")
		else:
			d.life -= delta
			if d.life < 0.6: d.chunk.position.y -= delta * 1.5
			if d.life <= 0:
				d.chunk.queue_free(); debris.remove_at(k)

func update_traps(delta: float) -> void:
	for t in traps:
		var inside = absf(P.x - t.x) < 2.4 and absf(P.z - t.z) < 2.4
		match t.st:
			"idle":
				t.panel.position.x = 0.0
				if inside and state == "play":
					t.st = "shake"; t.t = 0.8; sfx.play("creak"); burst(Vector3(t.x, t.y + 5.2, t.z), 10, [0xaaa69c], 1, 1, 0.06, 5)
			"shake":
				t.t -= delta; t.panel.position.x = sin(clock_t * 60) * 0.08; t.panel.rotation.z = sin(clock_t * 40) * 0.03
				if t.t <= 0: t.st = "fall"; t.vy = 0.0; t.cables.visible = false
			"fall":
				t.vy += 32.0 * delta; t.py -= t.vy * delta
				if t.py <= 0.25:
					t.py = 0.25; t.st = "down"; t.t = 3.0; sfx.play("thud"); shake = maxf(shake, 0.4)
					burst(Vector3(t.x, t.y + 0.4, t.z), 26, [0x9a968c, 0xbab6ac], 5, 1, 0.2, 4)
					if state == "play" and absf(P.x - t.x) < 1.9 and absf(P.z - t.z) < 1.9: hurt("trap")
			"down":
				t.t -= delta
				if t.t <= 0: t.st = "rise"; t.cables.visible = true
			"rise":
				t.py += 2.2 * delta; t.panel.rotation.z = 0.0
				if t.py >= 5.6: t.py = 5.6; t.st = "cool"; t.t = 1.2
			"cool":
				t.t -= delta
				if t.t <= 0: t.st = "idle"
		t.panel.position.y = t.py

func ambient(delta: float) -> void:
	for it in items:
		if it.got: continue
		it.ph += delta; it.model.rotation.y += delta * 1.5; it.model.position.y = 1.0 + sin(it.ph * 2.5) * 0.15
	for t in tokens:
		if t.got: continue
		t.st.rotation.y += delta * 2.5; t.st.position.y = 1.2 + sin(clock_t * 3) * 0.15
	for z in zones:
		z.ph += delta; z.dm.albedo_color.a = 0.45 + 0.2 * sin(z.ph * 2); z.ring.scale = Vector3.ONE * (1.0 + 0.03 * sin(z.ph * 3))
	for l in lamps:
		var f = sin(clock_t * 13 + l.ph) * sin(clock_t * 7.3 + l.ph * 2); var on = f > -0.85
		l.L.light_energy = 1.3 + f * 0.15 if on else 0.1; l.bulb.albedo_color = C(0xffd08a) if on else C(0x332a20)
	if pad_beam:
		pad_beam.material_override.albedo_color.a = (0.22 if P.carry > 0 else 0.1) + 0.05 * sin(clock_t * 3)
		pad_star.rotation.y += delta * 1.5; pad_star.position.y = 1.6 + sin(clock_t * 2) * 0.2
	if not crane.is_empty():
		crane.top.rotation.y = sin(clock_t * 0.08) * 0.45
	update_smoke(delta)
	if dust: dust.position = Vector3(P.x, P.y + 3, P.z)
	if weather: weather.position = Vector3(P.x, P.y + (16.0 if li == 1 else 12.0), P.z)
	plight.position = Vector3(P.x, P.y + 3, P.z)
	clouds.position = cam.position; clouds.rotation.y += delta * 0.004
	for k in range(pops.size() - 1, -1, -1):
		var p: Dictionary = pops[k]; p.t += delta; p.n.position.y += delta * 1.2
		p.n.modulate.a = minf(1.0, (1.8 - p.t) * 2.0); p.n.outline_modulate.a = p.n.modulate.a
		if p.t > 1.8:
			p.n.queue_free(); pops.remove_at(k)

# ============================================================ main menu hero shot
func hero_pose() -> void:
	var o = oleg
	reset_pose()
	o.root.position = Vector3(P.x, P.y, P.z); o.root.rotation.y = P.face; o.root.visible = true
	o.legs[0].rotation = Vector3(-0.32, 0, -0.1); o.knees[0].rotation.x = 0.42
	o.legs[1].rotation = Vector3(0.18, 0, 0.12); o.knees[1].rotation.x = 0.08
	o.arms[0].rotation = Vector3(0.15, 0, -0.55); o.elbows[0].rotation = Vector3(-0.6, 0, 1.25)
	o.arms[1].rotation = Vector3(-1.25, 0, 0.1); o.elbows[1].rotation.x = -0.35
	var breathe = sin(clock_t * 1.4) * 0.012
	o.body.position.y = -0.04 + breathe; o.body.rotation.x = -0.06
	o.head.rotation = Vector3(-0.05 + sin(clock_t * 0.5) * 0.02, sin(clock_t * 0.3) * 0.06, 0)
	o.led.albedo_color = C(0xffd23a) if int(clock_t * 2.0) % 2 == 0 else C(0x8aff5a)

func hero_menu(delta: float) -> void:
	menu_t += delta
	# school mode: if this computer is slow, switch to low graphics automatically
	if not aq.done and menu_t > 2.0:
		aq.t += raw_delta; aq.n += 1
		if aq.t >= 4.0:
			aq.done = true
			if hq and aq.n / aq.t < 28.0:
				set_quality(false)
				hud.show_msg("School mode", "Low graphics turned on for this computer. Press G to switch back.", 4.0)
	hero_pose()
	var f = Vector2(sin(P.face), cos(P.face)); var right = Vector2(-f.y, f.x)
	var sway = sin(menu_t * 0.12)
	var c2 = HERO - f * (7.2 + sin(menu_t * 0.07) * 0.5) - right * (1.5 + sway * 0.4)
	var ch = h(c2.x, c2.y)
	var want = Vector3(c2.x, maxf(ch + 0.6, P.y + 0.55) + sway * 0.12, c2.y)
	cam.position = want if menu_t < 0.1 else cam.position.lerp(want, minf(1.0, 2.0 * delta))
	var look2 = HERO + f * 30.0 - right * 12.0
	cam.look_at(Vector3(look2.x, P.y + 2.6, look2.y))

func make_flag(x: float, z: float) -> void:
	var y = h(x, z)
	Mk.mi(world, Mk.CYL, pbr(0x8a8a86, 0.4, 0.7), Vector3(x, y + 2.1, z), Vector3(0.05, 4.2, 0.05))
	Mk.mi(world, Mk.SPH, pbr(0xc0973e, 0.3, 0.9), Vector3(x, y + 4.25, z), Vector3.ONE * 0.09)
	if flag_mat == null:
		var img = Image.create_empty(256, 160, false, Image.FORMAT_RGBA8); img.fill(C(0xb8221a))
		Mk.speckle(img, 500, [C(0x9a1a12), C(0xc83228)], 0.3)
		var pts = HUDStar.points(Vector2(52, 44), 26.0)
		for py in range(10, 80):
			for px in range(20, 85):
				if Geometry2D.is_point_in_polygon(Vector2(px, py), pts):
					img.set_pixel(px, py, C(0xf0c040))
		var sh = Shader.new()
		sh.code = """shader_type spatial;
render_mode cull_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
void vertex() {
	float w = UV.x;
	VERTEX.z += sin(TIME * 4.2 - UV.x * 7.0) * 0.2 * w;
	VERTEX.y += sin(TIME * 2.7 - UV.x * 5.0) * 0.06 * w;
}
void fragment() {
	ALBEDO = texture(tex, UV).rgb;
	ROUGHNESS = 0.8;
	BACKLIGHT = vec3(0.35);
}"""
		flag_mat = ShaderMaterial.new(); flag_mat.shader = sh; flag_mat.set_shader_parameter("tex", Mk.tex(img))
	var q = QuadMesh.new(); q.size = Vector2(2.4, 1.5); q.subdivide_width = 16; q.subdivide_depth = 4
	var fl = Mk.mi(world, q, flag_mat, Vector3(x - 1.2, y + 3.45, z)); fl.rotation.y = PI; fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	circles.append(Vector3(x, z, 0.2))

# ============================================================ cutscene
func update_cutscene(delta: float) -> void:
	cut.t += delta; var T = 7.5; var t: float = cut.t
	hud.set_title_alpha(clampf((t - 0.5) / 1.0, 0.0, 1.0) * clampf((5.6 - t) / 1.0, 0.0, 1.0))
	if t < T:
		var u = 1.0 - pow(1.0 - t / T, 2); var n = PATH.size() - 1; var f = u * n; var i = mini(n - 1, int(f)); var k = f - i
		var a: Vector2 = PATH[i]; var b: Vector2 = PATH[i + 1]
		var x = lerpf(a.x, b.x, k); var z = lerpf(a.y, b.y, k); var y = h(x, z)
		var fa = atan2(b.x - a.x, b.y - a.y)
		bike.g.position = Vector3(x, y, z); bike.g.rotation = Vector3(0, fa, sin(t * 3) * 0.03)
		var spd = (1.0 - t / T) * 2.0 + 0.2
		for w in bike.wheels: w.rotate_object_local(Vector3.UP, -delta * spd * 8)
		var o = oleg
		o.root.position = Vector3(x, y + 0.32, z); o.root.rotation.y = fa; o.body.rotation.x = 0.25
		var ph = t * spd * 5
		o.legs[0].rotation.x = -1.15 + sin(ph) * 0.45; o.legs[1].rotation.x = -1.15 - sin(ph) * 0.45
		o.knees[0].rotation.x = 1.35 + cos(ph) * 0.4; o.knees[1].rotation.x = 1.35 - cos(ph) * 0.4
		o.arms[0].rotation = Vector3(-1.1, 0, 0); o.arms[1].rotation = Vector3(-1.1, 0, 0); o.elbows[0].rotation.x = -0.35; o.elbows[1].rotation.x = -0.35
		o.head.rotation = Vector3(-0.1, 0, 0)
		P.x = x; P.z = z; P.y = y
		cam.position = cam.position.lerp(Vector3(x + 5, y + 3, z + 9), minf(1.0, 3.0 * delta)); cam.look_at(Vector3(x, y + 1.4, z))
		if t > 3.6 and cut.stage == 0:
			cut.stage = 1; hud.subs("Товарищ Олег едет на работу…", "Comrade Oleg rides in on his old bicycle…")
	else:
		if cut.stage < 2:
			cut.stage = 2; reset_pose(); P.x = START.x; P.z = START.y; P.y = h(P.x, P.z); P.face = PI
			hud.subs("Четвёртый энергоблок. Его нужно восстановить!", "Block No. 4 is still smoking. It must be rebuilt!")
			say("Четвёртый энергоблок. За работу!", "ru", 0.6, 0.85)
		anim_oleg(delta, 0); oleg.head.rotation.y = 0
		cam.position = cam.position.lerp(Vector3(P.x + 1.5, P.y + 3.6, P.z + 6.5), minf(1.0, 1.6 * delta))
		cam.look_at(Vector3(lerpf(P.x, -4, 0.5), lerpf(P.y + 1.5, 20, 0.6), lerpf(P.z, -36, 0.7)))
		if t > T + 4.2: end_cutscene()

# ============================================================ level complete / win
func level_stars() -> int:
	return 1 + (1 if lost_level == 0 else 0) + (1 if level_t <= PAR[li] else 0)

func star_text() -> String:
	var s = int(level_t)
	return "Level complete   ·   %s   ·   Time %d:%02d %s" % ["No lives lost" if lost_level == 0 else "Lives lost: %d" % lost_level, s / 60, s % 60,
		"(under %d:%02d!)" % [int(PAR[li]) / 60, int(PAR[li]) % 60] if level_t <= PAR[li] else "(beat %d:%02d for a star)" % [int(PAR[li]) / 60, int(PAR[li]) % 60]]

func level_complete() -> void:
	if li < LEVELS.size() - 1:
		state = "levelDone"; sfx.play("fanfare"); P.cheer = 2.0; var L: Dictionary = LEVELS[li]
		hud.show_msg(L.done_ru, L.done_en, 2.0)
		var st = level_stars()
		save.unlocked = maxi(int(save.unlocked), li + 1); save.stars[li] = maxi(int(save.stars[li]), st); write_save()
		await get_tree().create_timer(1.8).timeout
		hud.set_card_text("done", L.done_ru, "Excellent work, comrade! " + L.done_en, L.done_txt + "\n\n" + star_text() + "\n\nDID YOU KNOW?\n" + LEVEL_FACTS[li])
		hud.set_card_stars("done", st); hud.show_card("done")
	else:
		state = "won"; won_t = 0.0; P.cheer = 99.0; sfx.music_on = false
		var st = level_stars(); save.unlocked = 2; save.stars[2] = maxi(int(save.stars[2]), st); write_save(); hud.set_card_stars("win", st)
		if march.stream:
			march.volume_db = -2.0; march.play()
		else:
			sfx.play("anthem")
		hud.set_hud_visible(false); hud.set_detector(0.12, false, -70, 0, 0)

func update_win(delta: float) -> void:
	won_t += delta; var k = clampf(won_t / 6.0, 0.0, 1.0)
	facade_mat.emission_energy_multiplier = k * 1.1; facade2_mat.emission_energy_multiplier = k * 1.1
	star_mat.emission_energy_multiplier = 0.4 + k * 2.0 + sin(clock_t * 4) * 0.3
	env.ambient_light_energy = lerpf(0.28, 0.6, k); sun.light_energy = lerpf(0.45, 1.1, k); sun.light_color = C(0xffd8a0)
	env.fog_depth_end = lerpf(115, 200, k); env.fog_light_color = Color(lerpf(0.1, 0.55, k), lerpf(0.13, 0.45, k), lerpf(0.16, 0.42, k))
	sky_mat.sky_top_color = C(0x05070d).lerp(C(0x1c2440), k); sky_mat.sky_horizon_color = C(0x222c38).lerp(C(0xf0a070), k)
	smoke_target = 0.0
	if pad_beam: pad_beam.visible = false
	var a = 0.35 + won_t * 0.07; var cx = -6.0; var cz = -37.0
	cam.position = cam.position.lerp(Vector3(cx + sin(a) * 78, 30 + sin(won_t * 0.3) * 3, cz + cos(a) * 78), minf(1.0, 1.2 * delta)); cam.look_at(Vector3(cx, 24, cz))
	oleg.root.rotation.y = atan2(cam.position.x - P.x, cam.position.z - P.z)
	if randf() < delta * 2.2:
		burst(Vector3(R(-35, 25), R(40, 62), R(-40, -15)), 45, [0xd0302a, 0xe8c35a, 0xfff0d0], 11, 1.8, 0.3, 2); sfx.play("pop", -4.0)
	if won_t > 1.5 and not said:
		said = true; pop_text(Vector3(0, 36, -28), "ТЫ НАСТОЯЩИЙ ГЕРОЙ, ТОВАРИЩ!", "You are a real hero, comrade!", C(0xff5a4a))
		if say("Ю ар э рил хироу, камрад!", "ru", 0.6, 0.8):
			say("Ты настоящий герой, товарищ!", "ru", 0.6, 0.85)
		else:
			say("You are a real hero, comrade!", "en", 0.6, 0.8)
	if won_t > 5.5 and not hud.card_open("win"):
		var s = int(play_t)
		hud.set_card_text("win", "ТЫ НАСТОЯЩИЙ ГЕРОЙ, ТОВАРИЩ!", "You are a real hero, comrade!",
			"Энергоблок №4 восстановлен!\nBlock No. 4 has been rebuilt and the smoke has stopped.\nOleg earns the medal \"Hero of Labour\"!\n\nTotal time %d:%02d   ·   Stars earned: %d / 9\n\nDID YOU KNOW?\n%s" % [s / 60, s % 60, total_stars(), LEVEL_FACTS[2]])
		hud.show_card("win")
