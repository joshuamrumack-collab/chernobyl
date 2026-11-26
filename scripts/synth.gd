extends Node
## All sounds and music are synthesised in code: no audio files needed.

const RATE := 22050
var players := {}
var pluck_players := {}
var transpose := 0
var step := 0
var loop_n := 0
var mt := 0.0
var music_on := true
var wind: AudioStreamPlayer
var drone: AudioStreamPlayer
var rain: AudioStreamPlayer

const MEL := [69, -1, 72, -1, 76, -1, 74, 72, 71, -1, -1, -1, 69, -1, -1, -1, 64, -1, 69, -1, 71, -1, 72, 74, 71, -1, -1, 68, 69, -1, -1, -1,
	76, -1, 77, 76, 74, -1, 72, -1, 71, -1, 72, 71, 69, -1, -1, -1, 65, -1, 69, -1, 72, -1, 71, 69, 68, -1, -1, -1, 69, -1, -1, -1]
const BASS := [45, 45, 50, 52, 45, 41, 50, 52]

func _ready() -> void:
	_make("pick", _arp([69, 72, 76, 81], 0.06, 0.25, "tri", 0.35))
	_make("life", _arp([62, 66, 69, 74, 78], 0.07, 0.2, "sq", 0.22))
	_make("deposit", _arp([57, 64], 0.12, 0.3, "tri", 0.45))
	_make("fanfare", _fanfare())
	_make("over", _arp([69, 65, 64, 57], 0.32, 0.45, "tri", 0.5))
	_make("anthem", _anthem())
	var b := _buf(0.45); _tone(b, 0, 110, 0.4, "sine", 0.9, 40); _noise(b, 0, 0.4, 0.8, 0.08); _make("thud", b)
	b = _buf(0.8); _tone(b, 0, 90, 0.7, "saw", 0.2, 140); _tone(b, 0, 140, 0.6, "saw", 0.15, 95); _noise(b, 0, 0.6, 0.15, 0.6); _make("creak", b)
	b = _buf(0.75); _whistle(b); _make("whistle", b)
	b = _buf(0.45); _tone(b, 0, 300, 0.4, "tri", 0.5, 90); _make("hurt", b)
	b = _buf(0.35); _noise(b, 0, 0.25, 0.4, 0.4); _tone(b, 0, 700, 0.3, "sine", 0.15, 200); _make("pop", b)
	b = _buf(0.03); _noise(b, 0, 0.014, 1.6, 0.35, true); _tone(b, 0, 3200, 0.01, "sq", 0.25); _make("click", b, 8)
	_make("egg", _fife())
	b = _buf(0.12); _noise(b, 0, 0.1, 0.9, 0.06); _make("step_soft", b, 4)
	b = _buf(0.1); _noise(b, 0, 0.06, 0.7, 0.35); _tone(b, 0, 180, 0.05, "sine", 0.35, 90); _make("step_hard", b, 4)
	b = _buf(0.5); _noise(b, 0, 0.35, 0.35, 0.5, true); _tone(b, 0.0, 1400, 0.06, "sq", 0.12); _tone(b, 0.38, 1400, 0.06, "sq", 0.12); _make("radio", b, 2)
	var rb := _buf(3.0); var y := 0.0
	for i in rb.size():
		var x := randf() * 2.0 - 1.0; y += (x - y) * 0.25
		rb[i] = (x - y) * 0.45 + (0.5 if randf() < 0.0008 else 0.0)
	rain = AudioStreamPlayer.new(); rain.stream = _wav(rb, true); rain.volume_db = -14.0; add_child(rain)
	wind = AudioStreamPlayer.new(); wind.stream = _wind(); wind.volume_db = -9.0; add_child(wind); wind.play()
	drone = AudioStreamPlayer.new(); drone.stream = _drone(); drone.volume_db = -13.0; add_child(drone); drone.play()

func play(name: String, vol_db: float = 0.0, pitch: float = 1.0) -> void:
	var p: AudioStreamPlayer = players.get(name)
	if p:
		p.volume_db = vol_db; p.pitch_scale = pitch; p.play()

func set_key(t: int) -> void:
	transpose = t
	drone.pitch_scale = pow(2.0, t / 12.0)

func set_rain(on: bool) -> void:
	if on and not rain.playing: rain.play()
	elif not on: rain.stop()

func set_muted(m: bool) -> void:
	AudioServer.set_bus_mute(0, m)

func _process(delta: float) -> void:
	if not music_on:
		return
	mt += delta
	while mt >= 0.4:
		mt -= 0.4
		if step % 8 == 0:
			_pluck(BASS[step / 8] + transpose - 12, -6.0)
		if loop_n % 3 != 2 and MEL[step] >= 0:
			_pluck(MEL[step] + transpose, -9.0)
		step += 1
		if step >= 64:
			step = 0; loop_n += 1

func _pluck(midi: int, vol: float) -> void:
	if not pluck_players.has(midi):
		var b := _buf(1.6)
		for k in 5:
			_tone(b, k * 0.058, _mtof(midi), 0.14, "tri", 0.5 * (1.0 - k * 0.16))
		_echo(b, 0.42, 0.42)
		var p := AudioStreamPlayer.new(); p.stream = _wav(b); p.max_polyphony = 3; add_child(p)
		pluck_players[midi] = p
	var pp: AudioStreamPlayer = pluck_players[midi]
	pp.volume_db = vol; pp.play()

# ------------------------------------------------------------ synthesis
func _mtof(m: float) -> float:
	return 440.0 * pow(2.0, (m - 69.0) / 12.0)

func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array(); b.resize(int(sec * RATE)); return b

func _osc(type: String, ph: float) -> float:
	var f := fposmod(ph, 1.0)
	match type:
		"sq": return 1.0 if f < 0.5 else -1.0
		"saw": return f * 2.0 - 1.0
		"tri": return 1.0 - 4.0 * absf(f - 0.5)
	return sin(ph * TAU)

func _tone(b: PackedFloat32Array, t0: float, f: float, dur: float, type: String, vol: float, slide: float = 0.0) -> void:
	var s0 := int(t0 * RATE); var n := int(dur * RATE); var ph := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= b.size():
			break
		var k := float(i) / n
		var fr := f * pow(slide / f, k) if slide > 0.0 else f
		ph += fr / RATE
		var env := minf(1.0, i / (0.01 * RATE)) * pow(0.001, k)
		b[idx] += _osc(type, ph) * vol * env

func _noise(b: PackedFloat32Array, t0: float, dur: float, vol: float, lp: float = 0.2, hp: bool = false) -> void:
	var s0 := int(t0 * RATE); var n := int(dur * RATE); var y := 0.0
	for i in n:
		var idx := s0 + i
		if idx >= b.size():
			break
		var x := randf() * 2.0 - 1.0
		y += (x - y) * lp
		var v := (x - y) if hp else y
		b[idx] += v * vol * pow(0.001, float(i) / n)

func _echo(b: PackedFloat32Array, delay: float, fb: float) -> void:
	var d := int(delay * RATE)
	for i in range(d, b.size()):
		b[i] += b[i - d] * fb

func _whistle(b: PackedFloat32Array) -> void:
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += (2600.0 + sin(t * TAU * 28.0) * 180.0) / RATE
		var env := minf(1.0, t / 0.02) * (1.0 if t < 0.55 else maxf(0.0, 1.0 - (t - 0.55) / 0.15))
		b[i] = sin(ph * TAU) * 0.35 * env

func _arp(notes: Array, gap: float, dur: float, type: String, vol: float) -> PackedFloat32Array:
	var b := _buf(gap * notes.size() + dur + 0.1)
	for i in notes.size():
		_tone(b, i * gap, _mtof(notes[i]), dur, type, vol)
	return b

func _fanfare() -> PackedFloat32Array:
	var b := _buf(2.6)
	var chords := [[57, 61, 64], [62, 66, 69], [64, 68, 71], [69, 73, 76]]
	for i in 4:
		var d := 1.2 if i == 3 else 0.4
		for m in chords[i]:
			_tone(b, i * 0.38, _mtof(m), d, "saw", 0.09)
		_tone(b, i * 0.38, _mtof(chords[i][0] - 12), d, "tri", 0.3)
	return b

## Short original fife-and-drum march for the Easter egg.
func _fife() -> PackedFloat32Array:
	var notes := [[74, 0.25], [79, 0.25], [79, 0.25], [81, 0.25], [83, 0.5], [79, 0.5], [81, 0.25], [83, 0.25], [84, 0.25], [86, 0.25], [83, 0.5], [79, 0.5],
		[86, 0.25], [84, 0.25], [83, 0.25], [81, 0.25], [79, 0.25], [81, 0.25], [83, 0.25], [78, 0.25], [79, 1.0]]
	var b := _buf(6.5); var t := 0.1
	for n in notes:
		var d: float = n[1] * 0.42
		_tone(b, t, _mtof(n[0]), d * 0.95, "tri", 0.22); _tone(b, t, _mtof(n[0]) * 2.0, d * 0.5, "sine", 0.05)
		t += d
	var dt := 0.1
	while dt < t:
		_noise(b, dt, 0.08, 0.5, 0.5); _tone(b, dt, 120, 0.1, "sine", 0.35, 70)
		_noise(b, dt + 0.21, 0.05, 0.25, 0.6)
		dt += 0.42
	return b

func _anthem() -> PackedFloat32Array:
	var seq := [[62, .5], [67, 1], [62, .75], [64, .25], [66, 1], [59, .5], [59, .5], [64, 1], [62, .75], [60, .25], [62, 1], [55, .5], [55, .5],
		[57, 1], [57, .75], [59, .25], [60, 1], [60, .75], [62, .25], [64, 1], [66, .75], [67, .25], [69, 1.5]]
	var b := _buf(12.0); var t := 0.2
	for s in seq:
		var d: float = s[1] * 0.55
		_tone(b, t, _mtof(s[0]), d + 0.1, "saw", 0.1)
		_tone(b, t, _mtof(s[0] - 12), d + 0.1, "tri", 0.22)
		t += d
	return b

func _wind() -> AudioStreamWAV:
	var b := _buf(8.0); var y := 0.0; var y2 := 0.0
	for i in b.size():
		var t := float(i) / b.size()
		var x := randf() * 2.0 - 1.0
		var cut := 0.03 + 0.03 * (0.5 + 0.5 * sin(t * TAU))
		y += (x - y) * cut; y2 += (y - y2) * 0.5
		b[i] = (y - y2 * 0.3) * (0.9 + 0.6 * sin(t * TAU * 2.0 + 1.0))
	return _wav(b, true)

func _drone() -> AudioStreamWAV:
	var b := _buf(4.0); var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var x := _osc("saw", t * 55.0) + _osc("saw", t * 55.25) + _osc("saw", t * 82.5)
		lp += (x - lp) * 0.08
		b[i] = lp * 0.12
	return _wav(b, true)

func _wav(b: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = RATE; w.stereo = false
	var bytes := PackedByteArray(); bytes.resize(b.size() * 2)
	for i in b.size():
		bytes.encode_s16(i * 2, int(clampf(b[i], -1.0, 1.0) * 32000.0))
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_begin = 0; w.loop_end = b.size()
	return w

func _make(name: String, b: PackedFloat32Array, poly: int = 4) -> void:
	var p := AudioStreamPlayer.new(); p.stream = _wav(b); p.max_polyphony = poly
	add_child(p); players[name] = p
