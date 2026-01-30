extends Camera3D

@export var target_path: NodePath = "../Goose" # point to goose node
var target: Node3D
var offset: Vector3

func _ready():
	target = get_node(target_path)
	offset = position - target.position

func _process(_delta):
	if target:
		position = target.position + offset
