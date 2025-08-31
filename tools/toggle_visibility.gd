@tool
extends EditorScript

# Configuration
const INCLUDE_NESTED_CHILDREN = true

func _run():
	var selection = EditorInterface.get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		push_error("No nodes selected. Please select a parent node.")
		return
	
	for node in selected_nodes:
		if node:
			toggle_children_visibility(node)
	
	# Mark the scene as modified so changes can be saved
	EditorInterface.mark_scene_as_unsaved()

func toggle_children_visibility(parent_node: Node):
	print("Toggling visibility for children of: ", parent_node.name)
	
	var toggled_count = 0
	
	if INCLUDE_NESTED_CHILDREN:
		# Recursively toggle all descendants
		toggled_count = toggle_visibility_recursive(parent_node, 0, true)  # Skip the parent itself
	else:
		# Only toggle direct children
		for child in parent_node.get_children():
			if toggle_single_node_visibility(child):
				toggled_count += 1
	
	print("Toggle complete. Total nodes toggled: ", toggled_count)

func toggle_visibility_recursive(node: Node, count: int, skip_current: bool = false) -> int:
	# Toggle current node's visibility (unless we're skipping it)
	if not skip_current and toggle_single_node_visibility(node):
		count += 1
	
	# Process all children
	for child in node.get_children():
		count = toggle_visibility_recursive(child, count, false)
	
	return count

func toggle_single_node_visibility(node: Node) -> bool:
	# Check if the node has a visible property
	if node.has_method("set_visible"):
		var was_visible = node.visible
		node.visible = !node.visible
		print("Toggled ", node.name, ": ", was_visible, " -> ", node.visible)
		return true
	else:
		# Node doesn't have visibility property, skip it
		return false
