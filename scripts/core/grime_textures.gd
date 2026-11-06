class_name GrimeTextures
extends RefCounted
## Procedural decal textures for oil stains, soot, puddles, scorch marks and wall streaks.
## Alpha shaping is a pure function so it can be unit tested; images are cached per kind.

enum Kind { OIL, SOOT, PUDDLE, SCORCH, RUST_STREAK, SOOT_STREAK }

const SIZE: int = 128
const BLOB_EDGE: float = 0.45

static var _cache: Dictionary = {}


static func color_of(kind: Kind) -> Color:
	match kind:
		Kind.OIL:
			return Color(0.05, 0.045, 0.04, 0.8)
		Kind.SOOT:
			return Color(0.02, 0.02, 0.02, 0.6)
		Kind.PUDDLE:
			return Color(0.07, 0.09, 0.11, 0.65)
		Kind.SCORCH:
			return Color(0.04, 0.025, 0.015, 0.85)
		Kind.RUST_STREAK:
			return Color(0.42, 0.19, 0.07, 0.6)
		_:
			return Color(0.03, 0.03, 0.03, 0.55)


static func is_streak(kind: Kind) -> bool:
	return kind == Kind.RUST_STREAK or kind == Kind.SOOT_STREAK


## Alpha in [0, 1] at texture coordinate (u, v) given a noise sample n in [-1, 1].
## Blobs fade to zero at the inscribed circle; streaks fade to zero at the left/right edges and the bottom.
static func alpha_at(kind: Kind, u: float, v: float, n: float) -> float:
	var noise01: float = clampf(n * 0.5 + 0.5, 0.0, 1.0)
	if is_streak(kind):
		var across: float = absf(u - 0.5) * 2.0
		var width: float = 0.35 + 0.25 * noise01
		var side_falloff: float = clampf(1.0 - across / width, 0.0, 1.0)
		var drip: float = pow(clampf(1.0 - v, 0.0, 1.0), 0.7)
		return clampf(side_falloff * drip * (0.5 + 0.5 * noise01), 0.0, 1.0)
	var r: float = Vector2(u - 0.5, v - 0.5).length() * 2.0
	var falloff: float = clampf((1.0 - r) / BLOB_EDGE, 0.0, 1.0)
	var solidity: float = 1.2 if kind == Kind.PUDDLE or kind == Kind.OIL else 0.9
	return clampf(falloff * (0.25 + noise01 * solidity), 0.0, 1.0)


static func get_texture(kind: Kind) -> ImageTexture:
	if _cache.has(kind):
		return _cache[kind] as ImageTexture
	var texture: ImageTexture = ImageTexture.create_from_image(_build_image(kind))
	_cache[kind] = texture
	return texture


static func _build_image(kind: Kind) -> Image:
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 4100 + int(kind)
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 4
	noise.frequency = 0.035 if not is_streak(kind) else 0.06
	var tint: Color = color_of(kind)
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	for y: int in SIZE:
		for x: int in SIZE:
			var u: float = (float(x) + 0.5) / float(SIZE)
			var v: float = (float(y) + 0.5) / float(SIZE)
			# Streaks stretch their noise vertically so they read as drips.
			var n: float = noise.get_noise_2d(float(x), float(y) * (0.25 if is_streak(kind) else 1.0))
			var alpha: float = alpha_at(kind, u, v, n) * tint.a
			var shade: float = 0.8 + 0.2 * (n * 0.5 + 0.5)
			image.set_pixel(x, y, Color(tint.r * shade, tint.g * shade, tint.b * shade, alpha))
	image.generate_mipmaps()
	return image
