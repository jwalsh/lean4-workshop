/-!
# W04: Inductive types (FPIL 1.5)

Run:   lean exercises/warmup/W04_Inductive.lean

Three functions over a binary tree, each by pattern matching on the
constructors. `toList` is in-order: left subtree, value, right subtree.
-/

inductive Tree (α : Type) where
  | leaf
  | node (l : Tree α) (v : α) (r : Tree α)
deriving Repr

namespace Tree

def size {α : Type} : Tree α → Nat := sorry
def mirror {α : Type} : Tree α → Tree α := sorry
-- In-order traversal.
def toList {α : Type} : Tree α → List α := sorry

end Tree

open Tree in
def t : Tree Nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf)

#guard t.size = 3
#guard t.toList = [1, 2, 3]
#guard t.mirror.toList = [3, 2, 1]
