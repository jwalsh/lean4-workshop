-- Lists.lean: classic first list functions, each with a #guard (the test)
-- and a #eval (the example). Put the cursor on a #eval line to see its value.
-- Reset to stubs: git show db2a0a6:scratch/Lists.lean > scratch/Lists.lean

namespace Lists

def len { a' : Type } : List a' -> Nat
  | [] => 0
  | _ :: xs => 1 + len xs
#guard len [1, 2, 3] = 3
#eval len ["a", "b", "c"]

def append {a' : Type} : List a' -> List a' -> List a'
  | [], ys => ys
  | x :: xs, ys => x :: append xs ys
#guard append [1] [2, 3] = [1, 2, 3]
#eval append [1, 2] [3, 4]

def reverse {a' : Type} : List a' -> List a'
  | [] => []
  | x :: xs => append (reverse xs) [x]
#guard reverse [1, 2, 3] = [3, 2, 1]
#eval reverse ["x", "y", "z"]

def member {a' : Type} [BEq a'] : a' -> List a' -> Bool
  | _, [] => false
  | e, x :: xs => if x == e then true else member e xs
#guard member 2 [1, 2, 3] = true
#guard member 9 [1, 2, 3] = false
#eval member "b" ["a", "b", "c"]

def nth? {a' : Type} : List a' -> Nat -> Option a'
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => nth? xs n
#guard nth? [10, 20, 30] 1 = some 20
#guard nth? [10, 20, 30] 3 = none
#eval nth? ["a", "b", "c"] 2

def last? {a' : Type} : List a' -> Option a'
  | [] => none
  | [x] => some x
  | _ :: xs => last? xs
#guard last? [1, 2, 3] = some 3
#eval last? ([] : List Nat)
#eval last? ([4, 5, 6] : List Nat)

def take {a' : Type} : Nat -> List a' -> List a'
  | 0, _ => []
  | _, [] => []
  | n + 1, x :: xs => x :: take n xs
#guard take 2 [1, 2, 3] = [1, 2]
#eval take 5 [1, 2, 3]
#eval last? (take 2 [1, 2, 3])

def flatten {a' : Type} : List (List a') -> List a'
  | [] => []
  | xs :: xss => append xs (flatten xss)
#guard flatten [[1], [2, 3], []] = [1, 2, 3]
#eval flatten [["a"], [], ["b", "c"]]

def map {a' b' : Type} : (a' -> b') -> List a' -> List b'
  | _, [] => []
  | f, x :: xs => f x :: map f xs
#guard map (· * 2) [1, 2, 3] = [2, 4, 6]
#eval map String.length ["hi", "there"]

def filter {a' : Type} : (a' -> Bool) -> List a' -> List a'
  | _, [] => []
  | p, x :: xs => if p x then x :: filter p xs else filter p xs
#guard filter (· % 2 == 0) [1, 2, 3, 4] = [2, 4]
#eval filter (· > 2) [1, 2, 3, 4, 5]

def foldr {a' b' : Type} : (a' -> b' -> b') -> b' -> List a' -> b'
  | _, init, [] => init
  | f, init, x :: xs => f x (foldr f init xs)
#guard foldr (· + ·) 0 [1, 2, 3] = 6
#eval foldr (fun x acc => x :: acc) [] [1, 2, 3]

def zip {a' b' : Type} : List a' -> List b' -> List (a' × b')
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => (x, y) :: zip xs ys
#guard zip [1, 2] ["a", "b", "c"] = [(1, "a"), (2, "b")]
#eval zip [1, 2, 3] [true, false]

def assoc? {k v : Type} [BEq k] : k -> List (k × v) -> Option v
  | _, [] => none
  | k, (k', v) :: rest => if k' == k then some v else assoc? k rest
#guard assoc? "b" [("a", 1), ("b", 2)] = some 2
#eval assoc? 3 [(1, "one"), (2, "two")]

end Lists

