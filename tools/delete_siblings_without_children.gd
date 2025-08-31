@tool
extends EditorScript

func _run():
	var selection = EditorInterface.get_selection()
	var selected_nodes = selection.get_selected_nodes()
	
	if selected_nodes.size() == 0:
		push_error("No nodes selected. Please select a node whose siblings you want to check.")
		return
	
	for node in selected_nodes:
		if node:
			delete_childless_siblings(node)
	
	# Mark the scene as modified so changes can be saved
	EditorInterface.mark_scene_as_unsaved()

func delete_childless_siblings(selected_node: Node):
	var parent = selected_node.get_parent()
	if not parent:
		push_error("Selected node has no parent, cannot find siblings.")
		return
	
	print("Checking siblings of: ", selected_node.name, " (parent: ", parent.name, ")")
	
	var siblings = parent.get_children()
	var nodes_to_delete = []
	var deleted_count = 0
	
	# First pass: identify nodes to delete
	for sibling in siblings:
		# Skip the selected node itself
		if sibling == selected_node:
			continue
		
		# Check if the sibling has no children
		if sibling.get_child_count() == 0:
			nodes_to_delete.append(sibling)
			print("Marked for deletion: ", sibling.name, " (no children)")
		else:
			print("Keeping: ", sibling.name, " (has ", sibling.get_child_count(), " children)")
	
	# Second pass: delete the identified nodes
	for node in nodes_to_delete:
		if is_instance_valid(node):  # Safety check
			print("Deleting: ", node.name)
			node.queue_free()
			deleted_count += 1
	
	print("Deletion complete. Total sibling nodes deleted: ", deleted_count)
