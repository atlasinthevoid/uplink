extends Node

class_name Xr

func _init(state: State):
	state.add_child(self)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var state: State = get_parent()
	for component in state.component_by_type["origin"]:
		var entity: String = state.component[component].entity
		if !state.entity[entity].has("game node"):
			var origin := XROrigin3D.new()
			state.add_child(origin)
			
			var camera := XRCamera3D.new()
			origin.add_child(camera)
			
			var left_controller := XRController3D.new()
			left_controller.tracker = "left_hand"
			origin.add_child(left_controller)
			
			var cube := MeshInstance3D.new();
			cube.mesh = BoxMesh.new()
			cube.scale = Vector3(0.25, 0.25, 0.25)
			left_controller.add_child(cube)
			
			var right_controller := XRController3D.new()
			left_controller.tracker = "right_hand"
			origin.add_child(right_controller)
			
			Attach.run(state, entity, GameNode.gen(origin))
