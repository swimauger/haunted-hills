@tool
extends EditorScript

# Configuration
const INCLUDE_NESTED_CHILDREN = true
const PRESERVE_ORIGINAL_NAMES = true
const MESHES_SUBDIRECTORY = "meshes"

func _run():
	# Get the selected directory from FileSystem dock
	var base_path = get_selected_directory()
	if base_path == "":
		push_error("Please select a directory in the FileSystem dock first.")
		return
	
	# Append /meshes to the export path
	var export_path = base_path + MESHES_SUBDIRECTORY + "/"
	
	# Create the meshes directory if it doesn't exist
	create_export_directory(export_path)
	
	var selection = EditorInterface.get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		print("No nodes selected. Using scene root.")
		var scene_root = get_scene()
		if scene_root:
			selected_nodes = [scene_root]
		else:
			push_error("No scene is open.")
			return
	
	for node in selected_nodes:
		if node:
			export_meshes_from_node(node, export_path)

func get_selected_directory() -> String:
	var selected_paths = EditorInterface.get_selected_paths()
	
	if selected_paths.size() == 0:
		return ""
	
	var selected_path = selected_paths[0]
	
	# If it's a file, get its directory
	if FileAccess.file_exists(selected_path):
		selected_path = selected_path.get_base_dir()
	
	# Ensure it ends with a slash
	if not selected_path.ends_with("/"):
		selected_path += "/"
	
	return selected_path

func create_export_directory(export_path: String):
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(export_path):
		var result = dir.make_dir_recursive(export_path.trim_prefix("res://"))
		if result != OK:
			push_error("Failed to create export directory: " + export_path)
		else:
			print("Created export directory: ", export_path)

func export_meshes_from_node(root_node: Node, export_path: String):
	print("Starting mesh export from: ", root_node.name)
	print("Export directory: ", export_path)
	
	var mesh_instances = find_mesh_instances(root_node)
	var exported_count = 0
	var name_counter = {}  # Track duplicate names
	
	for mesh_instance in mesh_instances:
		if export_mesh(mesh_instance, export_path, name_counter):
			exported_count += 1
	
	print("Export complete. Total meshes exported: ", exported_count)

func find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var mesh_instances: Array[MeshInstance3D] = []
	
	# Check current node
	if node is MeshInstance3D and node.mesh != null:
		mesh_instances.append(node)
	
	# Check children if enabled
	if INCLUDE_NESTED_CHILDREN:
		for child in node.get_children():
			mesh_instances.append_array(find_mesh_instances(child))
	
	return mesh_instances

func export_mesh(mesh_instance: MeshInstance3D, export_path: String, name_counter: Dictionary) -> bool:
	var filename = generate_filename(mesh_instance, name_counter)
	var full_path = export_path + filename + ".mesh"
	
	# Preserve the original mesh name in the exported resource
	var mesh_to_save = mesh_instance.mesh
	if PRESERVE_ORIGINAL_NAMES:
		# Create a copy to avoid modifying the original
		mesh_to_save = mesh_instance.mesh.duplicate()
		
		# Set the resource name to preserve it
		if mesh_instance.mesh.resource_name != "":
			mesh_to_save.resource_name = mesh_instance.mesh.resource_name
		else:
			# Use the node name if mesh doesn't have a name
			mesh_to_save.resource_name = mesh_instance.name
	
	# Check if file already exists
	if FileAccess.file_exists(full_path):
		print("File already exists, overwriting: ", full_path)
	
	var result = ResourceSaver.save(mesh_to_save, full_path)
	
	if result == OK:
		print("Exported: ", mesh_instance.name, " -> ", full_path)
		return true
	else:
		push_error("Failed to export mesh from " + mesh_instance.name + " to " + full_path)
		return false

func generate_filename(mesh_instance: MeshInstance3D, name_counter: Dictionary) -> String:
	# Always use the MeshInstance3D node name as the base
	var base_name = sanitize_filename(mesh_instance.name)
	
	# Fallback if node name is empty or becomes empty after sanitization
	if base_name == "":
		base_name = "unnamed_mesh"
	
	# Handle duplicate names by adding a counter
	var final_name = base_name
	if name_counter.has(base_name):
		name_counter[base_name] += 1
		final_name = base_name + "_" + str(name_counter[base_name])
	else:
		name_counter[base_name] = 0
	
	return final_name

func sanitize_filename(name: String) -> String:
	# Convert to snake_case and remove invalid characters
	var sanitized = name.to_snake_case()
	sanitized = sanitized.replace(" ", "_")
	# Remove any characters that aren't alphanumeric, underscore, or hyphen
	var regex = RegEx.new()
	regex.compile("[^a-zA-Z0-9_-]")
	sanitized = regex.sub(sanitized, "", true)
	
	return sanitized
