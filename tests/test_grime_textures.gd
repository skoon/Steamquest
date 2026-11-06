extends TestCase

const ALL_KINDS: Array[GrimeTextures.Kind] = [
	GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT, GrimeTextures.Kind.PUDDLE,
	GrimeTextures.Kind.SCORCH, GrimeTextures.Kind.RUST_STREAK, GrimeTextures.Kind.SOOT_STREAK,
]


func test_alpha_stays_in_range() -> void:
	for kind: GrimeTextures.Kind in ALL_KINDS:
		for step: int in 11:
			var u: float = float(step) / 10.0
			for n: float in [-1.0, 0.0, 1.0]:
				var alpha: float = GrimeTextures.alpha_at(kind, u, 1.0 - u, n)
				assert_true(alpha >= 0.0 and alpha <= 1.0, "alpha out of range for kind %d" % kind)


func test_blobs_fade_out_before_the_edge() -> void:
	for kind: GrimeTextures.Kind in [GrimeTextures.Kind.OIL, GrimeTextures.Kind.SOOT, GrimeTextures.Kind.PUDDLE, GrimeTextures.Kind.SCORCH]:
		for n: float in [-1.0, 1.0]:
			assert_almost(GrimeTextures.alpha_at(kind, 0.0, 0.5, n), 0.0, "left edge clear for kind %d" % kind)
			assert_almost(GrimeTextures.alpha_at(kind, 0.0, 0.0, n), 0.0, "corner clear for kind %d" % kind)
		assert_true(GrimeTextures.alpha_at(kind, 0.5, 0.5, 1.0) > 0.5, "centre is stained for kind %d" % kind)


func test_streaks_fade_at_sides_and_bottom() -> void:
	for kind: GrimeTextures.Kind in [GrimeTextures.Kind.RUST_STREAK, GrimeTextures.Kind.SOOT_STREAK]:
		assert_almost(GrimeTextures.alpha_at(kind, 0.0, 0.2, 1.0), 0.0, "streak side clear")
		assert_almost(GrimeTextures.alpha_at(kind, 0.5, 1.0, 1.0), 0.0, "streak bottom clear")
		assert_true(GrimeTextures.alpha_at(kind, 0.5, 0.1, 1.0) > GrimeTextures.alpha_at(kind, 0.5, 0.8, 1.0), "streak strongest at the top")


func test_texture_is_cached_and_sized() -> void:
	var first: ImageTexture = GrimeTextures.get_texture(GrimeTextures.Kind.OIL)
	assert_eq(first.get_width(), GrimeTextures.SIZE, "texture width")
	assert_true(first == GrimeTextures.get_texture(GrimeTextures.Kind.OIL), "same texture instance reused")
