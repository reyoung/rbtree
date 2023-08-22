module rbtree

enum Color {
	red
	black
}

struct RBTreeNode[K, V] {
pub mut:
	color  Color
	key    K
	value  V
	left   &RBTreeNode[K, V] = unsafe { nil }
	right  &RBTreeNode[K, V] = unsafe { nil }
	parent &RBTreeNode[K, V] = unsafe { nil }
}

[unsafe]
fn (mut n RBTreeNode[K, V]) free() {
}

[unsafe]
fn (n &RBTreeNode[K, V]) free_all() {
	unsafe {
		if n.left != nil {
			n.left.free_all()
		}
		if n.right != nil {
			n.right.free_all()
		}
		n.free()
	}
}

fn (n &RBTreeNode[K, V]) ptr_equals(b &RBTreeNode[K, V]) bool {
	return unsafe { voidptr(n) == voidptr(b) }
}

fn left_rotate[K, V](root_ &RBTreeNode[K, V], x_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	mut x := unsafe { *&x_ }
	mut y := x.right
	x.right = y.left
	if y.left != unsafe { nil } {
		y.left.parent = x
	}
	y.parent = x.parent

	if x.parent == unsafe { nil } {
		root = y
	} else if x.ptr_equals(x.parent.left) {
		x.parent.left = y
	} else {
		x.parent.right = y
	}
	y.left = x
	x.parent = y
	return root
}

fn right_rotate[K, V](root_ &RBTreeNode[K, V], x_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	mut x := unsafe { *&x_ }
	mut y := x.left
	x.left = y.right
	if y.right != unsafe { nil } {
		y.right.parent = x
	}
	y.parent = x.parent

	if x.parent == unsafe { nil } {
		root = y
	} else if x.ptr_equals(x.parent.right) {
		x.parent.right = y
	} else {
		x.parent.left = y
	}
	y.right = x
	x.parent = y
	return root
}

fn grandparent_node[K, V](node &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	if node.parent == unsafe { nil } {
		return unsafe { nil }
	}
	return node.parent.parent
}

fn uncle_node[K, V](node &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut grandparent := grandparent_node[K, V](node)
	if grandparent == unsafe { nil } {
		return unsafe { nil }
	}

	if node.parent.ptr_equals(grandparent.left) {
		return grandparent.right
	} else {
		return grandparent.left
	}
}

fn insert_fixup[K, V](root_ &RBTreeNode[K, V], z_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	mut z := unsafe { *&z_ }
	if z.parent == unsafe { nil } {
		z.color = .black
		return z
	}
	if z.parent.color == .black {
		return root
	}

	mut uncle := uncle_node[K, V](z)
	mut grandparent := grandparent_node[K, V](z)
	if uncle != unsafe { nil } && uncle.color == .red {
		z.parent.color = .black
		uncle.color = .black
		grandparent.color = .red
		return insert_fixup[K, V](root, grandparent)
	}

	if z.ptr_equals(z.parent.right) && z.parent.ptr_equals(grandparent.left) {
		root = left_rotate[K, V](root, z.parent)
		z = z.left
	} else if z.ptr_equals(z.parent.left) && z.parent.ptr_equals(grandparent.right) {
		root = right_rotate[K, V](root, z.parent)
		z = z.right
	}
	z.parent.color = .black
	grandparent.color = .red
	if z.ptr_equals(z.parent.left) {
		root = right_rotate[K, V](root, grandparent)
	} else {
		root = left_rotate[K, V](root, grandparent)
	}

	return root
}

fn insert_with_new_node[K, V](root &RBTreeNode[K, V], z_ &RBTreeNode[K, V], less fn (a K, b K) bool) &RBTreeNode[K, V] {
	mut z := unsafe { *&z_ }
	mut y := &RBTreeNode[K, V](unsafe { nil })
	mut x := unsafe { *&root }
	for x != unsafe { nil } {
		y = x
		if less(z.key, x.key) {
			x = x.left
		} else {
			x = x.right
		}
	}
	z.parent = y
	mut new_root := unsafe { *&root }
	if y == unsafe { nil } {
		new_root = z
	} else if less(z.key, y.key) {
		y.left = z
	} else {
		y.right = z
	}

	return insert_fixup[K, V](new_root, z)
}

[manualfree]
fn insert[K, V](root &RBTreeNode[K, V], k K, v V, less fn (a K, b K) bool) &RBTreeNode[K, V] {
	mut z := &RBTreeNode[K, V]{
		key: k
		value: v
		color: .red
	}

	return insert_with_new_node[K, V](root, z, less)
}

fn delete_fixup[K, V](root_ &RBTreeNode[K, V], node_ &RBTreeNode[K, V], parent_ &RBTreeNode[K, V]) {
	mut root := unsafe { *&root_ }
	mut node := unsafe { *&node_ }
	mut parent := unsafe { *&parent_ }
	mut other := &RBTreeNode[K, V](unsafe { nil })
	for (node == unsafe { nil } || node.color == .black) && !node.ptr_equals(root) {
		if parent.left.ptr_equals(node) {
			other = parent.right
			if other.color == .red {
				other.color = .black
				parent.color = .red
				root = left_rotate[K, V](root, parent)
				other = parent.right
			}
			if (other.left == unsafe { nil } || other.left.color == .black)
				&& (other.right == unsafe { nil } || other.right.color == .black) {
				other.color = .red
				node = parent
				parent = node.parent
			} else {
				if other.right == unsafe { nil } || other.right.color == .black {
					other.left.color = .black
					other.color = .red
					root = right_rotate[K, V](root, other)
					other = parent.right
				}
				other.color = parent.color
				parent.color = .black
				other.right.color = .black
				root = left_rotate[K, V](root, parent)
				node = root
				break
			}
		} else {
			other = parent.left
			if other.color == .red {
				other.color = .black
				parent.color = .red
				root = right_rotate[K, V](root, parent)
				other = parent.left
			}
			if (other.left == unsafe { nil } || other.left.color == .black)
				&& (other.right == unsafe { nil } || other.right.color == .black) {
				other.color = .red
				node = parent
				parent = node.parent
			} else {
				if other.left == unsafe { nil } || other.left.color == .black {
					other.right.color = .black
					other.color = .red
					root = left_rotate[K, V](root, other)
					other = parent.left
				}
				other.color = parent.color
				parent.color = .black
				other.left.color = .black
				root = right_rotate[K, V](root, parent)
				node = root
				break
			}
		}
	}
	if node != unsafe { nil } {
		node.color = .black
	}
}

[manualfree]
fn delete_node[K, V](root_ &RBTreeNode[K, V], node_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	mut node := unsafe { *&node_ }
	mut child := &RBTreeNode[K, V](unsafe { nil })
	mut parent := &RBTreeNode[K, V](unsafe { nil })
	mut color := Color.red

	if node.left != unsafe { nil } && node.right != unsafe { nil } {
		mut replace := node
		replace = replace.right
		for replace.left != unsafe { nil } {
			replace = replace.left
		}
		if node.parent != unsafe { nil } {
			if node.parent.left == node {
				node.parent.left = replace
			} else {
				node.parent.right = replace
			}
		} else {
			root = replace
		}
		child = replace.right
		parent = replace.parent
		color = replace.color
		if parent == node {
			parent = replace
		} else {
			if child != unsafe { nil } {
				child.parent = parent
			}
			parent.left = child
			replace.right = node.right
			node.right.parent = replace
		}
		replace.parent = node.parent
		replace.color = node.color
		replace.left = node.left
		node.left.parent = replace
		if color == .black {
			delete_fixup[K, V](root, child, parent)
		}
		unsafe { node.free() }
		return root
	}
	if node.left != unsafe { nil } {
		child = node.left
	} else {
		child = node.right
	}
	parent = node.parent
	color = node.color
	if child != unsafe { nil } {
		child.parent = parent
	}
	if parent != unsafe { nil } {
		if parent.left == node {
			parent.left = child
		} else {
			parent.right = child
		}
	} else {
		root = child
	}
	if color == .black {
		delete_fixup[K, V](root, child, parent)
	}
	unsafe { node.free() }

	return root
}

fn lower_bound[K, V](root_ &RBTreeNode[K, V], key K, less fn (a K, b K) bool) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	if root == unsafe { nil } {
		return root
	}
	mut node := root
	mut result := &RBTreeNode[K, V](unsafe { nil })
	for node != unsafe { nil } {
		if less(node.key, key) {
			node = node.right
		} else {
			result = node
			node = node.left
		}
	}
	return result
}

fn find[K, V](root_ &RBTreeNode[K, V], key K, less fn (a K, b K) bool) &RBTreeNode[K, V] {
	mut root := unsafe { *&root_ }
	if root == unsafe { nil } {
		return root
	}
	mut node := root
	for node != unsafe { nil } {
		if less(node.key, key) {
			node = node.right
		} else if less(key, node.key) {
			node = node.left
		} else {
			return node
		}
	}
	return node
}

pub struct RBTree[K, V] {
	less_than ?fn (a K, b K) bool
mut:
	root &RBTreeNode[K, V] = unsafe { nil }
}

pub fn (mut t RBTree[K, V]) empty() bool {
	return t.root == unsafe { nil }
}

[inline]
fn (t RBTree[K, V]) real_less_than(a K, b K) bool {
	less_than := t.less_than or { return a < b }

	return less_than(a, b)
}

[manualfree]
pub fn (mut t RBTree[K, V]) insert(k K, v V) &RBTreeNode[K, V] {
	mut z := &RBTreeNode[K, V]{
		key: k
		value: v
	}
	t.root = insert_with_new_node[K, V](t.root, z, t.real_less_than)
	return z
}

[unsafe]
pub fn (mut t RBTree[K, V]) free() {
	if t.root == unsafe { nil } {
		return
	}

	unsafe { t.root.free_all() }
}

pub fn (mut t RBTree[K, V]) erase(node &RBTreeNode[K, V]) {
	t.root = delete_node[K, V](t.root, node)
}

pub fn (t RBTree[K, V]) lower_bound(key K) &RBTreeNode[K, V] {
	return lower_bound[K, V](t.root, key, t.real_less_than)
}

pub fn (t RBTree[K, V]) find(key K) &RBTreeNode[K, V] {
	return find[K, V](t.root, key, t.real_less_than)
}

pub fn (t RBTree[K, V]) begin() &RBTreeNode[K, V] {
	mut node := t.root
	if node == unsafe { nil } {
		return node
	}
	for node.left != unsafe { nil } {
		node = node.left
	}
	return node
}

pub fn (t RBTree[K, V]) end() &RBTreeNode[K, V] {
	return &RBTreeNode[K, V](unsafe { nil })
}

pub fn (t RBTree[K, V]) next(node_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut node := unsafe { *&node_ }
	if node.right != unsafe { nil } {
		mut node2 := node.right
		for node2.left != unsafe { nil } {
			node2 = node2.left
		}
		return node2
	}
	mut parent := node.parent
	for parent != unsafe { nil } && node.ptr_equals(parent.right) {
		node = parent
		parent = parent.parent
	}
	return parent
}

pub fn (t RBTree[K, V]) prev(node_ &RBTreeNode[K, V]) &RBTreeNode[K, V] {
	mut node := unsafe { *&node_ }
	if node.left != unsafe { nil } {
		mut node2 := node.left
		for node2.right != unsafe { nil } {
			node2 = node2.right
		}
		return node2
	}
	mut parent := node.parent
	for parent != unsafe { nil } && node.ptr_equals(parent.left) {
		node = parent
		parent = parent.parent
	}
	return parent
}
