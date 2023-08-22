module rbtree

fn test_tree() {
	mut tree := &RBTree[int, int]{}
	defer {
		unsafe { tree.free() }
	}
	tree.insert(1, 2)
	tree.insert(3, 4)
	tree.insert(5, 6)
	mut node := tree.lower_bound(4)
	node = tree.prev(node)
	assert node.key == 3
}

fn test_node() {
	cmp := fn (a int, b int) bool {
		return a < b
	}
	mut new_root := insert[int, int](unsafe { nil }, 1, 2, cmp)
	defer {
		unsafe { new_root.free_all() }
	}
	new_root = insert[int, int](new_root, 2, 3, cmp)

	new_root = insert[int, int](new_root, 7, 8, cmp)
	new_root = insert[int, int](new_root, -3, 8, cmp)
	new_root = insert[int, int](new_root, 2, 8, cmp)
	new_root = insert[int, int](new_root, 5, 8, cmp)

	mut node := lower_bound[int, int](new_root, 3, cmp)
	assert node.key == 5
	assert node.value == 8
	node = find[int, int](new_root, 3, cmp)
	assert node == unsafe { nil }

	node = find[int, int](new_root, 2, cmp)
	assert node.key == 2
	assert node.value == 3

	new_root = delete_node[int, int](new_root, node)
	node = find[int, int](new_root, 2, cmp)
	assert node.key == 2
	assert node.value == 8
}
