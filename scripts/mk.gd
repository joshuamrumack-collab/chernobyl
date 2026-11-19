class_name Mk
## Small helpers to build meshes, materials and textures from code.

static var BOX := BoxMesh.new()
static var SPH := _sphere()
static var CYL := _cyl(12)
static var LCYL := _cyl(5)
static var _mats := {}
static var _caps := {}

## Capsule of radius r and total length len (cached).
static func cap(r: float, len: float) -> CapsuleMesh:
	var key := Vector2(r, len)
	if _caps.has(key):
		return _caps[key]
	var m := CapsuleMesh.new(); m.radius = r; m.height = maxf(len, r * 2.0); m.radial_segments = 16; m.rings = 6
	_caps[key] = m
	return m

static func _sphere() -> SphereMesh:
	var m := SphereMesh.new(); m.radius = 1.0; m.height = 2.0; m.radial_segments = 14; m.rings = 8; return m

static func _cyl(seg: int) -> CylinderMesh:
	var m := CylinderMesh.new(); m.top_radius = 1.0; m.bottom_radius = 1.0; m.height = 1.0; m.radial_segments = seg; m.rings = 1; return m

static func c(hex: int, a: float = 1.0) -> Color:
	return Color(((hex >> 16) & 255) / 255.0, ((hex >> 8) & 255) / 255.0, (hex & 255) / 255.0, a)

## Matte lit material (cached per colour).
static func lam(hex: int) -> StandardMaterial3D:
	if _mats.has(hex):
		return _mats[hex]
	var m := StandardMaterial3D.new()
	m.albedo_color = c(hex); m.roughness = 0.95
	_mats[hex] = m
	return m

static func glow(col: Color, additive: bool = true, tex: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	if tex:
		m.albedo_texture = tex
	m.disable_receive_shadows = true
	return m

static func tri(tex: Texture2D, scale: Vector3, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex; m.albedo_color = tint
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = scale
	m.roughness = 0.95
	return m

static func mi(parent: Node, mesh: Mesh, mat: Material, pos: Vector3, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh; n.material_override = mat
	n.position = pos; n.scale = scl
	parent.add_child(n)
	return n

static func box(parent: Node, mat: Material, pos: Vector3, size: Vector3) -> MeshInstance3D:
	return mi(parent, BOX, mat, pos, size)

static func seg_xform(a: Vector3, b: Vector3, r: float) -> Transform3D:
	var d := b - a
	var L := d.length()
	if L < 0.0001:
		return Transform3D(Basis.from_scale(Vector3(r, 0.001, r)), a)
	var dn := d / L
	var q: Quaternion
	if dn.dot(Vector3.UP) < -0.9999:
		q = Quaternion(Vector3.RIGHT, PI)
	else:
		q = Quaternion(Vector3.UP, dn)
	return Transform3D(Basis(q) * Basis.from_scale(Vector3(r, L, r)), a + d * 0.5)

static func cyl_between(parent: Node, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = CYL; n.material_override = mat
	n.transform = seg_xform(a, b, r)
	parent.add_child(n)
	return n

static func lattice(parent: Node, segs: Array, mat: Material, r: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = LCYL
	mm.instance_count = segs.size()
	for i in segs.size():
		mm.set_instance_transform(i, seg_xform(segs[i][0], segs[i][1], r))
	var n := MultiMeshInstance3D.new()
	n.multimesh = mm; n.material_override = mat
	parent.add_child(n)
	return n

static func lines(parent: Node, pts: PackedVector3Array, col: Color) -> MeshInstance3D:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for p in pts:
		im.surface_add_vertex(p)
	im.surface_end()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.albedo_color = col
	var n := MeshInstance3D.new(); n.mesh = im; n.material_override = m
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(n)
	return n

## Extruded five-point star (faces +Z).
static func star_mesh(r1: float = 1.0, r2: float = 0.42, depth: float = 0.3) -> ArrayMesh:
	var pts: Array[Vector2] = []
	for i in 10:
		var a := PI / 2.0 + i * PI / 5.0
		var r := r2 if i % 2 == 1 else r1
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var zf := depth / 2.0
	for i in 10:
		var a := pts[i]; var b := pts[(i + 1) % 10]
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(Vector3(0, 0, zf)); st.add_vertex(Vector3(b.x, b.y, zf)); st.add_vertex(Vector3(a.x, a.y, zf))
		st.set_normal(Vector3(0, 0, -1))
		st.add_vertex(Vector3(0, 0, -zf)); st.add_vertex(Vector3(a.x, a.y, -zf)); st.add_vertex(Vector3(b.x, b.y, -zf))
		var n := Vector3(b.y - a.y, -(b.x - a.x), 0).normalized()
		st.set_normal(n)
		st.add_vertex(Vector3(a.x, a.y, zf)); st.add_vertex(Vector3(b.x, b.y, zf)); st.add_vertex(Vector3(b.x, b.y, -zf))
		st.add_vertex(Vector3(a.x, a.y, zf)); st.add_vertex(Vector3(b.x, b.y, -zf)); st.add_vertex(Vector3(a.x, a.y, -zf))
	return st.commit()

## Flat pie slice on the ground, centred on +Z (for guard vision cones).
static func sector_mesh(radius: float, half: float, seg: int = 20) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in seg:
		var a0 := -half + 2.0 * half * i / seg
		var a1 := -half + 2.0 * half * (i + 1) / seg
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a0) * radius, 0, cos(a0) * radius))
		st.add_vertex(Vector3(sin(a1) * radius, 0, cos(a1) * radius))
	return st.commit()

static func disc_mesh(radius: float, inner: float = 0.0, seg: int = 32) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in seg:
		var a0 := TAU * i / seg; var a1 := TAU * (i + 1) / seg
		var o0 := Vector3(cos(a0), 0, sin(a0)); var o1 := Vector3(cos(a1), 0, sin(a1))
		if inner <= 0.0:
			st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(Vector3.ZERO)
			st.set_uv(Vector2(0.5 + o0.x * .5, 0.5 + o0.z * .5)); st.add_vertex(o0 * radius)
			st.set_uv(Vector2(0.5 + o1.x * .5, 0.5 + o1.z * .5)); st.add_vertex(o1 * radius)
		else:
			st.add_vertex(o0 * inner); st.add_vertex(o0 * radius); st.add_vertex(o1 * radius)
			st.add_vertex(o0 * inner); st.add_vertex(o1 * radius); st.add_vertex(o1 * inner)
	return st.commit()

# ------------------------------------------------------------ textures
static func radial(inner: Color, outer: Color, size: int = 64) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner); g.set_color(1, outer)
	var t := GradientTexture2D.new()
	t.gradient = g; t.width = size; t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5); t.fill_to = Vector2(1.0, 0.5)
	return t

static func speckle(img: Image, n: int, cols: Array, amax: float = 0.5) -> void:
	var w := img.get_width(); var h := img.get_height()
	for i in n:
		var x := randi() % w; var y := randi() % h
		var s := 1 + randi() % 3
		var col: Color = cols[i % cols.size()]
		var a := randf() * amax + 0.05
		for dx in s:
			for dy in s:
				var px := (x + dx) % w; var py := (y + dy) % h
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(col, a))

static func tex(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## 512 px = 6 m wide x 8 m tall of Soviet concrete panel facade with ribbon windows.
static func facade(emissive: bool) -> ImageTexture:
	var img := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK if emissive else c(0xcfccc3))
	if not emissive:
		speckle(img, 2600, [c(0xb8b5ac), c(0xe2dfd6), c(0xa6a39a)], 0.35)
		for x in range(0, 512, 128):
			img.fill_rect(Rect2i(x, 0, 2, 512), c(0xb4b0a6))
		for y in range(0, 512, 128):
			img.fill_rect(Rect2i(0, y, 512, 2), c(0xb4b0a6))
		for i in 14:
			var col := c(0xa88a6a) if randf() < 0.3 else c(0xaeaaa0)
			img.fill_rect(Rect2i(randi() % 500, 0, 3 + randi() % 6, randi() % 400), col)
	img.fill_rect(Rect2i(0, 141, 512, 51), Color.BLACK if emissive else c(0x22272a))
	for x in range(0, 512, 32):
		if emissive:
			if randf() < 0.8:
				img.fill_rect(Rect2i(x + 3, 145, 26, 43), c(0xffd27a))
		else:
			img.fill_rect(Rect2i(x, 141, 3, 51), c(0x565a5c))
			if randf() < 0.25:
				img.fill_rect(Rect2i(x + 3, 144, 26, 45), c(0x3a4246))
	if not emissive:
		img.fill_rect(Rect2i(0, 192, 512, 4), c(0x8a877f))
	img.fill_rect(Rect2i(0, 397, 512, 33), Color.BLACK if emissive else c(0x2a2f33))
	if emissive:
		for x in range(0, 512, 64):
			if randf() < 0.6:
				img.fill_rect(Rect2i(x + 6, 401, 50, 25), c(0xffcf70))
	return tex(img)

static func noise_img(base: Color, cols: Array, n: int, w: int = 128, h: int = 128) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(base)
	speckle(img, n, cols, 0.45)
	return img

static func stripes(a: Color, b: Color, n: int, vertical: bool, w: int = 64, h: int = 512) -> ImageTexture:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for i in n:
		var col := a if i % 2 == 0 else b
		if vertical:
			img.fill_rect(Rect2i(0, int(i * h / float(n)), w, int(h / float(n)) + 1), col)
		else:
			img.fill_rect(Rect2i(int(i * w / float(n)), 0, int(w / float(n)) + 1, h), col)
	speckle(img, 600, [c(0x555555), c(0x999999)], 0.2)
	return tex(img)

static func hazard() -> ImageTexture:
	var img := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			img.set_pixel(x, y, c(0x161616) if ((x + y) / 16) % 2 == 0 else c(0xe8c22a))
	return tex(img)

static func fence() -> ImageTexture:
	var img := noise_img(c(0xa19e96), [c(0x8a877f), c(0xc0bdb4)], 900, 256, 160)
	for y in range(10, 150, 24):
		var off := 16 if (y / 24) % 2 == 1 else 0
		for x in range(8 + off, 248, 32):
			img.fill_rect(Rect2i(x, y, 24, 14), c(0xbcb9b0))
			img.fill_rect(Rect2i(x + 2, y + 12, 24, 3), c(0x77746c))
			img.fill_rect(Rect2i(x + 22, y + 2, 3, 13), c(0x77746c))
	return tex(img)

static func radiation_sign() -> ImageTexture:
	var img := Image.create_empty(128, 160, false, Image.FORMAT_RGBA8)
	img.fill(c(0xe8c22a))
	for y in 160:
		for x in 128:
			if x < 6 or x > 121 or y < 6 or y > 153:
				img.set_pixel(x, y, c(0x111111))
	var cx := 64.0; var cy := 66.0
	for y in 160:
		for x in 128:
			var dx := x - cx; var dy := y - cy
			var d := sqrt(dx * dx + dy * dy)
			var a := fposmod(atan2(dy, dx) - PI / 2.0, TAU / 3.0)
			if d < 8 or (d > 13 and d < 40 and (a < 0.52 or a > TAU / 3.0 - 0.52)):
				img.set_pixel(x, y, c(0x111111))
	img.fill_rect(Rect2i(20, 118, 88, 10), c(0x111111))
	img.fill_rect(Rect2i(30, 136, 68, 8), c(0x111111))
	return tex(img)
