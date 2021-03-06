# Uplink Project
# GNU Affero General Public License v3.0 © 2022 atlasinthevoid

# Code snippets from https://github.com/19PHOBOSS98/Godot-MirrorInstance
# MIT License © 2020 19PHOBOSS98

extends Node
class_name MirrorCamera

func _init(state: State):
	state.add_child(self)

func _ready():
	pass

func _process(delta):
	var state: State = get_parent()
	for component in state.component_by_name["mirror"]:
		var entity: String = state.component[component].entity
		if !state.entity[entity].has("game node"):
			var mesh: MeshInstance3D = load("scene/mirror.tscn").instance()
			state.add_child(mesh)

			add_to_group("mirrors")
			# Sets the viewport_path to the right viewport for every instance of this scene ,Mi2's child(0)='View'
			#get("material/0").get("shader_param/refl_tx").set("viewport_path",find_node("View").get_path())

			$View.size = Vector2(ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
			# When all the camera's layer bits are turned on, the cull mask value is 1048575:  2^0 + 2^1 + 2^2 +...+2^19=1048575
			mesh.get_node("View/Camera").set("cull_mask",1048575)
			# While every layer is on this turns the chosen layer off
			mesh.get_node("View/Camera").set_cull_mask_bit(state.component[component]["ignore layer"]-1,false)
			Attach.run(state, "game_node", "mesh instance 3d", entity, mesh)
		else:
			var origin: String = state.component[state.component_by_name["origin"]].entity
			if state.entity[main_camera].has("game node"):
				update_cam(state.entity[main_camera]["game node"].global_transform, entity)
			pass

# The player's camera node calls this function to update the mirror-cameras position
# Shout out to Miziziziz who came up with this: https://www.youtube.com/watch?v=xXUVP6sN-tQ
func update_cam(main_cam_transform: Transform3D, entity: String):
	var state: State = get_parent()
	var mesh: MeshInstance3D = state.entity[entity]["game node"][0]
	mesh.scale.y *= -1
	mesh.get_node("DummyCam").global_transform = main_cam_transform
	mesh.scale.y *= -1
	mesh.get_node("View/Camera").global_transform = mesh.get_node("DummyCam").global_transform
	mesh.mirror_cam.global_transform.basis.x *= -1
	
	# Syncs mirror size with game window size but only changes mirror's viewport size when game window size changes instead of constantly updating size every second
	# Checks if game window size is not equal to mirror viewprt size
	if(mesh.get_node("View").size != get_viewport().size):
		# Interact with 't' to change it to true only if 't' isn't already true
		if(state.entity[entity]["mirror"][0]["t"] == false):
			state.entity[entity]["mirror"][0]["t"] = true
			# Only run once whenever 't' is changed
			mesh.get_node("View").size = get_viewport().size
		else:
			state.entity[entity]["mirror"][0]["t"] = false

# Recursively goes through a PhysicsBody node's branch to remember MeshInstances' layer mask 
# as it replaces it with the layer mask that the mirror's camera ignores
func _remember_MeshInstances(N, a: Dictionary, IgnoreLayer: int):
	if(N != null):
		# it checks if a MeshInstance it finds in the entering body is not yet added in the dictionary
		if((N.is_class("MeshInstance"))&&(!a.has(N))):
			# Stores MeshInstances in dictionary a
			a[N]=N.get_layer_mask()
			# Sets layer Mask bits to be all false except for the chosen layer
			N.set_layer_mask(0)
			# The layer mask bits are just 1 less than the actual layers
			N.set_layer_mask_bit(IgnoreLayer-1,true)
		if(N.get_child_count()!=0):
			# Checks if the node still has children that the code has to sift thru
			for i in N.get_child_count():
				# Recursion
				_remember_MeshInstances(N.get_child(i), a, IgnoreLayer)


# Goes thru the exiting body's stuff and restores each MeshInstancs' original layer mask
func _restore_Mesh_mask(N, a: Dictionary):
	if(N != null):
		# Checks if the MeshInstance has a saved layer mask in the dictionary
		if((N.is_class("MeshInstance"))&&(a.has(N))):
			# If it does it checks out of the HideArea with it
			N.set_layer_mask(a.get(N))
			# The saved layer mask is then erased from the dictionary
			a.erase(N)
		# Checks if the node still has children that the code has to go thru
		if(N.get_child_count()!=0):
			for i in N.get_child_count():
				# Recursion
				_restore_Mesh_mask(N.get_child(i), a)

# Sets the PhysicsBody to a layer mask that the mirror's camera ignores
func _on_HideArea_body_entered(body, a: Dictionary, IgnoreLayer: int):
	_remember_MeshInstances(body, a, IgnoreLayer)


# Puts the original cullmask value back after body exits the hide area
func _on_HideArea_body_exited(body, a: Dictionary):
	_restore_Mesh_mask(body, a)
