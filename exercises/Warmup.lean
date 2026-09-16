/-! Lean 4 warm-up exercises. Target: Lean 4.33 or newer, core only.
    Run: lean Warmup.lean ; lean --run Warmup.lean < file (exercise 9) -/

#eval 2 ^ 10
#eval "Maverick".length
#check fun (n : Nat) => n + 1

def ex1 : List Nat := sorry
#guard ex1.length = 3 ∧ ex1.sum = 10

def fact : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * fact n
#guard fact 5 = 120

def fib (n : Nat) : Nat := sorry
#guard fib 0 = 0
#guard fib 10 = 55
#guard fib 50 = 12586269025

structure Point where
  x : Float
  y : Float
deriving Repr

def Point.dist (p q : Point) : Float := sorry
#guard (Point.dist ⟨0, 0⟩ ⟨3, 4⟩ - 5.0).abs < 1e-9

inductive Tree (α : Type) where
  | leaf
  | node (l : Tree α) (v : α) (r : Tree α)
deriving Repr

namespace Tree
def size {α : Type} : Tree α → Nat := sorry
def mirror {α : Type} : Tree α → Tree α := sorry
def toList {α : Type} : Tree α → List α := sorry
end Tree

open Tree in
def t : Tree Nat := node (node leaf 1 leaf) 2 (node leaf 3 leaf)
#guard t.size = 3
#guard t.toList = [1, 2, 3]
#guard t.mirror.toList = [3, 2, 1]

def myNth? {α : Type} : List α → Nat → Option α := sorry
#guard myNth? [10, 20, 30] 1 = some 20
#guard myNth? ([] : List Nat) 0 = none
#guard myNth? [10, 20, 30] 3 = none

def myReverse {α : Type} : List α → List α := sorry
#guard myReverse [1, 2, 3] = [3, 2, 1]
#guard myReverse ([] : List Nat) = []

structure V2 where
  x : Int
  y : Int
deriving Repr, DecidableEq

instance : Add V2 := sorry
instance : ToString V2 := sorry
#guard V2.mk 1 2 + V2.mk 3 4 = V2.mk 4 6
#guard toString (V2.mk 1 2) = "(1, 2)"

partial def myGcd (a b : Nat) : Nat :=
  if h : b = 0 then a else myGcd b (a % b)
#guard myGcd 48 18 = 6
#guard myGcd 17 5 = 1

def sumSquares (n : Nat) : Nat := Id.run do
  let mut acc := 0
  for i in [1:n+1] do
    acc := acc + i * i
  return acc
#guard sumSquares 3 = 14

def primesBelow (n : Nat) : Array Nat := sorry
#guard primesBelow 30 = #[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]

def main : IO Unit := sorry

theorem myReverse_length {α : Type} (xs : List α) :
    (myReverse xs).length = xs.length := by
  sorry
