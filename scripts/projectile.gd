extends Node3D

var start_pos: Vector3
var target_pos: Vector3
var arc_height: float = 4.0
var flight_time: float = 0.5

func launch(from: Vector3, to: Vector3, duration: float = 0.5):
	start_pos = from
	target_pos = to
	flight_time = duration
	
	var tween = create_tween()
	tween.tween_method(animate_flight, 0.0, 1.0, flight_time).set_trans(Tween.TRANS_LINEAR)
	tween.finished.connect(queue_free)

func animate_flight(t: float):
	# linear interpolation for X and Z (Horizontal)
	var current_pos = start_pos.lerp(target_pos, t)
	
	# parabolic arc for Y
	# y = height * 4 * t * (1 - t)
	var y_offset = arc_height * (4.0 * t * (1.0 - t))
	current_pos.y += y_offset
	
	global_position = current_pos
