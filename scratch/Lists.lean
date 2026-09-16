-- Lists.lean: classic first list functions. Replace each sorry;
-- the #guard errors are the to-do list. C-c l c checks.

namespace Lists

def len { a' : Type } : List a' -> Nat
  | [] => 0
  | _ :: xs => 1 + len xs

def append {a' : Type} : List a' -> List a' -> List a'
  | [], ys => ys
  | x :: xs, ys => x :: append xs ys


def reverse {a' : Type} : List a' -> List a'
  | [] => []
  | x :: xs => append (reverse xs) [x]
#guard reverse [1, 2, 3] = [3, 2, 1]

def member {a' : Type} [BEq a'] : a' -> List a' -> Bool := sorry
#guard member 2 [1, 2, 3] = true
#guard member 9 [1, 2, 3] = false

def nth? {a' : Type} : List a' -> Nat -> Option a' := sorry
#guard nth? [10, 20, 30] 1 = some 20
#guard nth? [10, 20, 30] 3 = none

def last? {a' : Type} : List a' -> Option a' := sorry
#guard last? [1, 2, 3] = some 3

def take {a' : Type} : Nat -> List a' -> List a' := sorry
#guard take 2 [1, 2, 3] = [1, 2]

def flatten {a' : Type} : List (List a') -> List a' := sorry
#guard flatten [[1], [2, 3], []] = [1, 2, 3]

def map {a' b' : Type} : (a' -> b') -> List a' -> List b' := sorry
#guard map (· * 2) [1, 2, 3] = [2, 4, 6]

def filter {a' : Type} : (a' -> Bool) -> List a' -> List a' := sorry
#guard filter (· % 2 == 0) [1, 2, 3, 4] = [2, 4]

def foldr {a' b' : Type} : (a' -> b' -> b') -> b' -> List a' -> b' := sorry
#guard foldr (· + ·) 0 [1, 2, 3] = 6

def zip {a' b' : Type} : List a' -> List b' -> List (a' × b') := sorry
#guard zip [1, 2] ["a", "b", "c"] = [(1, "a"), (2, "b")]

def assoc? {k v : Type} [BEq k] : k -> List (k × v) -> Option v := sorry
#guard assoc? "b" [("a", 1), ("b", 2)] = some 2

end Lists
