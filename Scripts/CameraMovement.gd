extends Camera2D


var tween : Tween
var zoom_min := Vector2(0.005, 0.005)
var zoom_max := Vector2.ONE
var viewport_container : ViewportContainer
var mouse_pos := Vector2.ZERO
var drag := false


func _ready() -> void:
	viewport_container = get_parent().get_parent()
	tween = Tween.new()
	add_child(tween)
	tween.connect("tween_step", self, "_on_tween_step")


# Get the speed multiplier for when you've pressed
# a movement key for the given amount of time
func dir_move_zoom_multiplier(press_time : float) -> float:
	if press_time < 0:
		return 0.0
	if Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_CONTROL) :
		return Global.high_speed_move_rate
	elif Input.is_key_pressed(KEY_SHIFT):
		return Global.medium_speed_move_rate
	elif !Input.is_key_pressed(KEY_CONTROL):
		# control + right/left is used to move frames so
		# we do this check to ensure that there is no conflict
		return Global.low_speed_move_rate
	else:
		return 0.0

func reset_dir_move_time(direction) -> void:
	Global.key_move_press_time[direction] = 0.0


const key_move_action_names := ["ui_up", "ui_down", "ui_left", "ui_right"]

# Check if an event is a ui_up/down/left/right event-press :)
func is_action_direction_pressed(event : InputEvent, allow_echo: bool = true) -> bool:
	for action in key_move_action_names:
		if event.is_action_pressed(action, allow_echo):
			return true
	return false


# Check if an event is a ui_up/down/left/right event release nya
func is_action_direction_released(event: InputEvent) -> bool:
	for action in key_move_action_names:
		if event.is_action_released(action):
			return true
	return false


# get the Direction associated with the event.
# if not a direction event return null
func get_action_direction(event: InputEvent):  # -> Optional[Direction]
	if event.is_action("ui_up"):
		return Global.Direction.UP
	elif event.is_action("ui_down"):
		return Global.Direction.DOWN
	elif event.is_action("ui_left"):
		return Global.Direction.LEFT
	elif event.is_action("ui_right"):
		return Global.Direction.RIGHT
	return null


# Holds sign multipliers for the given directions nyaa
# (per the indices in Global.gd defined by Direction)
# UP, DOWN, LEFT, RIGHT in that order
const directional_sign_multipliers := [
	Vector2(0.0, -1.0),
	Vector2(0.0, 1.0),
	Vector2(-1.0, 0.0),
	Vector2(1.0, 0.0)
]

# Process an action event for a pressed direction
# action
func process_direction_action_pressed(event: InputEvent) -> void:
	var dir = get_action_direction(event)
	if dir == null:
		return
	var increment := get_process_delta_time()
	# Count the total time we've been doing this ^.^
	Global.key_move_press_time[dir] += increment
	var this_direction_press_time : float = Global.key_move_press_time[dir]
	var move_speed := dir_move_zoom_multiplier(this_direction_press_time)
	offset = offset + move_speed * increment * directional_sign_multipliers[dir] * zoom


# Process an action for a release direction action
func process_direction_action_released(event: InputEvent) -> void:
	var dir = get_action_direction(event)
	if dir == null:
		return
	reset_dir_move_time(dir)


func _input(event : InputEvent) -> void:
	mouse_pos = viewport_container.get_local_mouse_position()
	var viewport_size := viewport_container.rect_size
	if event.is_action_pressed("middle_mouse") || event.is_action_pressed("space"):
		drag = true
	elif event.is_action_released("middle_mouse") || event.is_action_released("space"):
		drag = false

	if Global.can_draw && Rect2(Vector2.ZERO, viewport_size).has_point(mouse_pos):
		if event.is_action_pressed("zoom_in"): # Wheel Up Event
			zoom_camera(-1)
		elif event.is_action_pressed("zoom_out"): # Wheel Down Event
			zoom_camera(1)
		elif event is InputEventMouseMotion && drag:
			offset = offset - event.relative * zoom
		elif is_action_direction_pressed(event):
			process_direction_action_pressed(event)
		elif is_action_direction_released(event):
			process_direction_action_released(event)

		Global.horizontal_ruler.update()
		Global.vertical_ruler.update()


# Zoom Camera
func zoom_camera(dir : int) -> void:
	var viewport_size := viewport_container.rect_size
	if Global.smooth_zoom:
		var zoom_margin = zoom * dir / 5
		var new_zoom = zoom + zoom_margin
		if new_zoom > zoom_min && new_zoom < zoom_max:
			var new_offset = offset + (-0.5 * viewport_size + mouse_pos) * (zoom - new_zoom)
			tween.interpolate_property(self, "zoom", zoom, new_zoom, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "offset", offset, new_offset, 0.05, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.start()

			if name == "Camera2D":
				Global.zoom_level_label.text = str(round(100 / new_zoom.x)) + " %"

	else:
		var prev_zoom := zoom
		var zoom_margin = zoom * dir / 10
		if zoom + zoom_margin > zoom_min:
			zoom += zoom_margin

		if zoom > zoom_max:
			zoom = zoom_max

		offset = offset + (-0.5 * viewport_size + mouse_pos) * (prev_zoom - zoom)
		if name == "Camera2D":
			Global.zoom_level_label.text = str(round(100 / Global.camera.zoom.x)) + " %"



func _on_tween_step(_object: Object, _key: NodePath, _elapsed: float, _value: Object) -> void:
	Global.horizontal_ruler.update()
	Global.vertical_ruler.update()
