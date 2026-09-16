/-! Solution to W05. -/

def myNth? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => myNth? xs n
#guard myNth? [10, 20, 30] 1 = some 20
#guard myNth? ([] : List Nat) 0 = none
#guard myNth? [10, 20, 30] 3 = none

def myReverse {α : Type} : List α → List α
  | [] => []
  | x :: xs => myReverse xs ++ [x]
#guard myReverse [1, 2, 3] = [3, 2, 1]
#guard myReverse ([] : List Nat) = []
