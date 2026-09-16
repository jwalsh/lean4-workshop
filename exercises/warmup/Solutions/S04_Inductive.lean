/-! Solution to W04. -/

inductive Tree (α : Type) where
  | leaf
  | node (l : Tree α) (v : α) (r : Tree α)
deriving Repr

namespace Tree

def size {α : Type} : Tree α → Nat
  | leaf => 0
  | node l _ r => l.size + 1 + r.size

def mirror {α : Type} : Tree α → Tree α
  | leaf => leaf
  | node l v r => node r.mirror v l.mirror

def toList {α : Type} : Tree α → List α
  | leaf => []
  | node l v r => l.toList ++ [v] ++ r.toList

end Tree

open Tree in
def t : Tree Nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf)

#guard t.size = 3
#guard t.toList = [1, 2, 3]
#guard t.mirror.toList = [3, 2, 1]
