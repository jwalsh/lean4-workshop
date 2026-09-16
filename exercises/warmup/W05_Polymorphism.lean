/-!
# W05: Polymorphism and Option (FPIL 1.6)

Run:   lean exercises/warmup/W05_Polymorphism.lean

These are P-99 problems #3 and #5. Keep your `myReverse`: W10 proves a
theorem about it.
-/

-- Zero-indexed lookup. Do not call `List.get?` / `List.getElem?`.
def myNth? {α : Type} : List α → Nat → Option α := sorry
#guard myNth? [10, 20, 30] 1 = some 20
#guard myNth? ([] : List Nat) 0 = none
#guard myNth? [10, 20, 30] 3 = none

-- Do not call `List.reverse`.
def myReverse {α : Type} : List α → List α := sorry
#guard myReverse [1, 2, 3] = [3, 2, 1]
#guard myReverse ([] : List Nat) = []
