class_name RailingLayout
extends RefCounted
## Splits one long edge of an open-air room into the solid railing spans left between its gaps.


## Solid spans as (start, end) in room-local X from 0 to `width`, for the gaps on `side`.
## Each gap is (local X centre, side, width); gaps on the other side are ignored.
static func solid_spans(width: float, side: int, gaps: PackedVector3Array) -> Array[Vector2]:
	assert(width > 0.0, "RailingLayout: width must be positive")
	var cuts: Array[Vector2] = []
	for gap: Vector3 in gaps:
		if int(gap.y) != side:
			continue
		assert(gap.z > 0.0, "RailingLayout: gap width must be positive")
		cuts.append(Vector2(clampf(gap.x - gap.z * 0.5, 0.0, width), clampf(gap.x + gap.z * 0.5, 0.0, width)))
	cuts.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var spans: Array[Vector2] = []
	var cursor: float = 0.0
	for cut: Vector2 in cuts:
		if cut.x > cursor + 0.05:
			spans.append(Vector2(cursor, cut.x))
		cursor = maxf(cursor, cut.y)
	if width > cursor + 0.05:
		spans.append(Vector2(cursor, width))
	return spans
