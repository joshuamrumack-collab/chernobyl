class_name HUDStar
## Five-point star outline, shared by the HUD and textures.

static func points(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.42
		p.append(c + Vector2(cos(a), sin(a)) * rr)
	return p
