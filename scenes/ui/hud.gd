class_name Hud
extends CanvasLayer
## Heads-up display. Driven entirely by GameState signals; never references 3D scene nodes.

const BRASS: Color = Color(0.78, 0.58, 0.26)
const PANEL_BG: Color = Color(0.09, 0.07, 0.05, 0.88)
const TEXT: Color = Color(1.0, 0.9, 0.72)
const NOTICE_TIME: float = 3.5
const ROOM_TOAST_TIME: float = 3.0
const LEVEL_CARD_TIME: float = 4.0
const CONTROLS_TEXT: String = "WASD move  |  Space steam-dash  |  LMB wrench  |  RMB rivet gun  |  R lubricant vent  |  F interact  |  Q/E rotate  |  Wheel zoom  |  Tab log  |  G maintenance"

var _health_bar: ProgressBar
var _health_label: Label
var _gauge: PressureGauge
var _friction_bar: ProgressBar
var _friction_label: Label
var _wear_bar: ProgressBar
var _wear_label: Label
var _vent_label: Label
var _status_label: Label
var _room_label: Label
var _prompt_label: Label
var _notice_label: Label
var _maintenance_panel: PanelContainer
var _socket_rows: Array[Dictionary] = []
var _log_panel: PanelContainer
var _log_list: ItemList
var _log_title: Label
var _log_body: RichTextLabel
var _log_hint: Label
var _overlay: ColorRect
var _overlay_title: Label
var _overlay_subtitle: Label
var _notice_time_left: float = 0.0
var _room_time_left: float = 0.0
var _level_card: VBoxContainer
var _level_card_act: Label
var _level_card_title: Label
var _level_card_time_left: float = 0.0
var _golden: bool = false
var _overclocked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_status_panel(root)
	_build_center_labels(root)
	_build_maintenance_panel(root)
	_build_log_panel(root)
	_build_level_card(root)
	_build_overlay(root)
	_build_controls_hint(root)
	_connect_signals()
	_refresh_maintenance(GameState.rig)


func _process(delta: float) -> void:
	if _notice_time_left > 0.0:
		_notice_time_left -= delta
		_notice_label.modulate.a = clampf(_notice_time_left, 0.0, 1.0)
	if _room_time_left > 0.0:
		_room_time_left -= delta
		_room_label.modulate.a = clampf(_room_time_left, 0.0, 1.0)
	if _level_card_time_left > 0.0:
		_level_card_time_left -= delta
		_level_card.modulate.a = clampf(_level_card_time_left, 0.0, 1.0)
		_level_card.visible = _level_card_time_left > 0.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_log"):
		_set_log_open(not _log_panel.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_maintenance"):
		_maintenance_panel.visible = not _maintenance_panel.visible
		_refresh_maintenance(GameState.rig)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and _log_panel.visible:
		_set_log_open(false)
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	GameState.health_changed.connect(_on_health_changed)
	GameState.pressure_changed.connect(_gauge.set_pressure)
	GameState.friction_updated.connect(_on_friction_updated)
	GameState.gears_changed.connect(_refresh_maintenance)
	GameState.overclock_changed.connect(_on_overclock_changed)
	GameState.vent_cooldown_changed.connect(_on_vent_cooldown_changed)
	GameState.rumor_discovered.connect(_on_rumor_discovered)
	GameState.log_opened.connect(_on_log_opened)
	GameState.golden_gear_acquired.connect(_on_golden_gear_acquired)
	GameState.room_entered.connect(_on_room_entered)
	GameState.interaction_prompt_changed.connect(_on_prompt_changed)
	GameState.notice_posted.connect(_show_notice)
	GameState.player_died.connect(_on_player_died)
	GameState.victory.connect(_on_victory)
	GameState.level_started.connect(_on_level_started)
	GameState.level_completed.connect(_on_level_completed)


# --- Signal handlers ------------------------------------------------------------

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "HULL INTEGRITY  %d / %d" % [int(ceil(current)), int(maximum)]


func _on_friction_updated(total_friction: float, worst_wear_percent: float) -> void:
	_friction_bar.value = total_friction
	_friction_label.text = "FRICTION  %.2f" % total_friction if not _golden else "FRICTION  0.00  (GOLDEN)"
	_wear_bar.value = worst_wear_percent
	_wear_label.text = "WORST TOOTH WEAR  %d%%" % int(worst_wear_percent)
	if _maintenance_panel.visible:
		_refresh_maintenance(GameState.rig)


func _on_overclock_changed(active: bool) -> void:
	_overclocked = active
	_update_status()


func _on_vent_cooldown_changed(time_left: float, _total: float) -> void:
	_vent_label.text = "LUBRICANT VENT [R]  READY" if time_left <= 0.0 else "LUBRICANT VENT [R]  %.0fs" % ceil(time_left)


func _on_rumor_discovered(rumor: RumorData) -> void:
	_rebuild_log_list()
	_show_notice("Rumor logged: %s  [Tab]" % rumor.title)


func _on_log_opened(rumor_id: StringName) -> void:
	_set_log_open(true)
	for i: int in GameState.rumor_order.size():
		if GameState.rumor_order[i] == rumor_id:
			_log_list.select(i)
			_show_rumor(rumor_id)
			return


func _on_golden_gear_acquired() -> void:
	_golden = true
	_update_status()
	_show_room_toast("THE GOLDEN GEAR RECOVERED")


func _on_room_entered(room_name: String) -> void:
	_show_room_toast(room_name.to_upper())


func _on_prompt_changed(text: String) -> void:
	_prompt_label.text = text
	_prompt_label.visible = not text.is_empty()


func _on_player_died() -> void:
	_show_overlay("RIG SEIZED", "The foundry claims another technician.\nPress Enter to restart this level.", Color(0.9, 0.3, 0.2))


func _on_victory() -> void:
	_show_overlay("THE GOLDEN GEAR", "Frictionless and flawless, it hums in your rig as the elevator rises\nfrom the Hargreaves Foundry. Press Enter to return to the title.", Color(1.0, 0.82, 0.35))


func _on_level_started(info: LevelInfo, index: int) -> void:
	_level_card_act.text = "%s  \u00b7  LEVEL %d" % [info.act_name.to_upper(), index + 1]
	_level_card_title.text = info.title.to_upper()
	_level_card_time_left = LEVEL_CARD_TIME
	_level_card.modulate.a = 1.0
	_level_card.visible = true


func _on_level_completed(_next_scene_path: String) -> void:
	_show_room_toast("DESCENDING...")


# --- Behaviour ------------------------------------------------------------------

func _show_notice(text: String) -> void:
	_notice_label.text = text
	_notice_time_left = NOTICE_TIME
	_notice_label.modulate.a = 1.0


func _show_room_toast(text: String) -> void:
	_room_label.text = text
	_room_time_left = ROOM_TOAST_TIME
	_room_label.modulate.a = 1.0


func _show_overlay(title: String, subtitle: String, color: Color) -> void:
	_set_log_open(false)
	_overlay_title.text = title
	_overlay_title.add_theme_color_override("font_color", color)
	_overlay_subtitle.text = subtitle
	_overlay.visible = true
	_prompt_label.visible = false


func _update_status() -> void:
	var parts: PackedStringArray = PackedStringArray()
	if _golden:
		parts.append("GOLDEN GEAR ENGAGED")
	if _overclocked:
		parts.append("OVERCLOCK!")
	_status_label.text = "  ".join(parts)
	_status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3) if _golden else Color(0.5, 0.95, 1.0))


func _set_log_open(open: bool) -> void:
	if open and _overlay.visible:
		return
	_log_panel.visible = open
	get_tree().paused = open
	if open:
		_rebuild_log_list()
		if GameState.rumor_order.is_empty():
			_log_title.text = "No logs recovered yet"
			_log_body.text = "Search the foundry for pneumatic-tube terminals."
			_log_hint.text = ""
		elif _log_list.get_selected_items().is_empty():
			_log_list.select(GameState.rumor_order.size() - 1)
			_show_rumor(GameState.rumor_order.back())


func _rebuild_log_list() -> void:
	var selected: PackedInt32Array = _log_list.get_selected_items()
	_log_list.clear()
	for rumor_id: StringName in GameState.rumor_order:
		_log_list.add_item(GameState.get_rumor(rumor_id).title)
	if not selected.is_empty() and selected[0] < _log_list.item_count:
		_log_list.select(selected[0])


func _show_rumor(rumor_id: StringName) -> void:
	var rumor: RumorData = GameState.get_rumor(rumor_id)
	assert(rumor != null, "Hud: unknown rumor %s" % rumor_id)
	_log_title.text = rumor.title
	_log_body.text = rumor.body
	_log_hint.text = "" if rumor.hint.is_empty() else "> " + rumor.hint


func _refresh_maintenance(rig: FrictionModel) -> void:
	if _socket_rows.is_empty():
		return
	for socket: int in FrictionModel.SOCKET_COUNT:
		var row: Dictionary = _socket_rows[socket]
		var gear: GearItem = rig.get_gear(socket)
		var name_label: Label = row["name"]
		var state_label: Label = row["state"]
		var friction_bar: ProgressBar = row["friction"]
		var wear_bar: ProgressBar = row["wear"]
		var output_label: Label = row["output"]
		if gear == null:
			name_label.text = "(empty socket)"
			state_label.text = "MISSING"
			friction_bar.value = 0.0
			wear_bar.value = 100.0
		else:
			name_label.text = gear.gear_name
			state_label.text = gear.state_label()
			friction_bar.value = gear.friction
			wear_bar.value = gear.wear_percent()
			var state_color: Color = TEXT
			if gear.is_golden_gear:
				state_color = Color(1.0, 0.82, 0.3)
			elif gear.state != GearItem.GearState.OK:
				state_color = Color(1.0, 0.35, 0.25)
			state_label.add_theme_color_override("font_color", state_color)
		output_label.text = "Output x%.2f   Wear %d%%" % [rig.speed_multiplier(socket), int(wear_bar.value)]


# --- Construction ------------------------------------------------------------------

## Anchors control to preset and sets its offsets from those anchors.
func _place(control: Control, preset: Control.LayoutPreset, left: float, top: float, right: float, bottom: float) -> void:
	control.set_anchors_preset(preset)
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _panel_style(border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_bar(max_value: float, fill: Color, width: float) -> ProgressBar:
	var bar: ProgressBar = ProgressBar.new()
	bar.max_value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 14)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0.18, 0.14, 0.1)
	background.border_color = BRASS.darkened(0.3)
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = fill
	fill_style.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


func _build_status_panel(root: Control) -> void:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(BRASS))
	panel.position = Vector2(16, 16)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	column.add_child(_make_label("TECHNICIAN RIG", 14, BRASS))
	_health_label = _make_label("HULL INTEGRITY", 13, TEXT)
	column.add_child(_health_label)
	_health_bar = _make_bar(100.0, Color(0.85, 0.22, 0.15), 300.0)
	_health_bar.value = 100.0
	column.add_child(_health_bar)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	_gauge = PressureGauge.new()
	row.add_child(_gauge)
	var stats_column: VBoxContainer = VBoxContainer.new()
	stats_column.add_theme_constant_override("separation", 4)
	row.add_child(stats_column)
	_friction_label = _make_label("FRICTION  0.00", 12, TEXT)
	stats_column.add_child(_friction_label)
	_friction_bar = _make_bar(GearItem.MAX_FRICTION, Color(0.95, 0.55, 0.15), 170.0)
	stats_column.add_child(_friction_bar)
	_wear_label = _make_label("WORST TOOTH WEAR  0%", 12, TEXT)
	stats_column.add_child(_wear_label)
	_wear_bar = _make_bar(100.0, Color(0.6, 0.6, 0.65), 170.0)
	stats_column.add_child(_wear_bar)
	_vent_label = _make_label("LUBRICANT VENT [R]  READY", 12, Color(0.6, 0.9, 0.75))
	stats_column.add_child(_vent_label)
	_status_label = _make_label("", 13, Color(0.5, 0.95, 1.0))
	column.add_child(_status_label)


func _build_center_labels(root: Control) -> void:
	_room_label = _make_label("", 30, BRASS.lightened(0.2))
	_room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_room_label, Control.PRESET_CENTER_TOP, -300, 24, 300, 64)
	root.add_child(_room_label)

	_notice_label = _make_label("", 18, TEXT)
	_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_notice_label, Control.PRESET_CENTER_BOTTOM, -400, -130, 400, -100)
	root.add_child(_notice_label)

	_prompt_label = _make_label("", 20, Color(1.0, 0.85, 0.45))
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_prompt_label, Control.PRESET_CENTER_BOTTOM, -400, -90, 400, -60)
	_prompt_label.visible = false
	root.add_child(_prompt_label)


func _build_controls_hint(root: Control) -> void:
	var hint: Label = _make_label(CONTROLS_TEXT, 12, Color(0.85, 0.75, 0.6, 0.8))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.offset_top = -28
	hint.offset_bottom = -8
	root.add_child(hint)


func _build_maintenance_panel(root: Control) -> void:
	_maintenance_panel = PanelContainer.new()
	_maintenance_panel.add_theme_stylebox_override("panel", _panel_style(BRASS))
	_place(_maintenance_panel, Control.PRESET_TOP_RIGHT, -376, 16, -16, 16)
	_maintenance_panel.custom_minimum_size = Vector2(360, 0)
	_maintenance_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_maintenance_panel.visible = false
	root.add_child(_maintenance_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_maintenance_panel.add_child(column)
	column.add_child(_make_label("GEAR SOCKETS - MAINTENANCE  [G]", 14, BRASS))
	for socket: int in FrictionModel.SOCKET_COUNT:
		var box: VBoxContainer = VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		column.add_child(box)
		var header: HBoxContainer = HBoxContainer.new()
		box.add_child(header)
		header.add_child(_make_label(FrictionModel.socket_name(socket).to_upper(), 12, BRASS.lightened(0.2)))
		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(spacer)
		var state_label: Label = _make_label("", 12, TEXT)
		header.add_child(state_label)
		var name_label: Label = _make_label("", 13, TEXT)
		box.add_child(name_label)
		box.add_child(_make_label("Friction", 10, Color(0.8, 0.7, 0.55)))
		var friction_bar: ProgressBar = _make_bar(GearItem.MAX_FRICTION, Color(0.95, 0.55, 0.15), 330.0)
		box.add_child(friction_bar)
		box.add_child(_make_label("Tooth wear", 10, Color(0.8, 0.7, 0.55)))
		var wear_bar: ProgressBar = _make_bar(100.0, Color(0.6, 0.6, 0.65), 330.0)
		box.add_child(wear_bar)
		var output_label: Label = _make_label("", 11, Color(0.75, 0.85, 0.8))
		box.add_child(output_label)
		_socket_rows.append({"name": name_label, "state": state_label, "friction": friction_bar, "wear": wear_bar, "output": output_label})


func _build_log_panel(root: Control) -> void:
	_log_panel = PanelContainer.new()
	_log_panel.add_theme_stylebox_override("panel", _panel_style(BRASS))
	_log_panel.custom_minimum_size = Vector2(820, 460)
	_place(_log_panel, Control.PRESET_CENTER, -410, -230, 410, 230)
	_log_panel.visible = false
	root.add_child(_log_panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_log_panel.add_child(column)
	column.add_child(_make_label("RUMOR & BLUEPRINT LOG   [Tab / Esc to close]", 16, BRASS))
	var row: HBoxContainer = HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)
	_log_list = ItemList.new()
	_log_list.custom_minimum_size = Vector2(250, 0)
	_log_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_list.item_selected.connect(func(index: int) -> void: _show_rumor(GameState.rumor_order[index]))
	row.add_child(_log_list)
	var detail: VBoxContainer = VBoxContainer.new()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 8)
	row.add_child(detail)
	_log_title = _make_label("", 20, BRASS.lightened(0.25))
	detail.add_child(_log_title)
	_log_body = RichTextLabel.new()
	_log_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_body.add_theme_color_override("default_color", TEXT)
	_log_body.add_theme_font_size_override("normal_font_size", 15)
	detail.add_child(_log_body)
	_log_hint = _make_label("", 14, Color(0.55, 0.95, 0.7))
	_log_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_log_hint)


func _build_level_card(root: Control) -> void:
	_level_card = VBoxContainer.new()
	_level_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_place(_level_card, Control.PRESET_CENTER_TOP, -400.0, 150.0, 400.0, 260.0)
	_level_card_act = _make_label("", 18, BRASS)
	_level_card_act.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_card.add_child(_level_card_act)
	_level_card_title = _make_label("", 44, TEXT)
	_level_card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_card.add_child(_level_card_title)
	_level_card.visible = false
	root.add_child(_level_card)


func _build_overlay(root: Control) -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.03, 0.02, 0.01, 0.78)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	root.add_child(_overlay)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	center.add_child(column)
	_overlay_title = _make_label("", 56, BRASS)
	_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_overlay_title)
	_overlay_subtitle = _make_label("", 20, TEXT)
	_overlay_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_overlay_subtitle)
