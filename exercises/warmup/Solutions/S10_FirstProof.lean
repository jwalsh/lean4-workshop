/-! Solution to W10. -/

def myReverse {α : Type} : List α → List α
  | [] => []
  | x :: xs => myReverse xs ++ [x]
#guard myReverse [1, 2, 3] = [3, 2, 1]

theorem myReverse_length {α : Type} (xs : List α) :
    (myReverse xs).length = xs.length := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [myReverse, List.length_append, ih]
