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

def member {a' : Type} [BEq a'] : a' -> List a' -> Bool
  | _, [] => false
  | e, x :: xs => if x == e then true else member e xs
#guard member 2 [1, 2, 3] = true
#guard member 9 [1, 2, 3] = false

def nth? {a' : Type} : List a' -> Nat -> Option a'
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => nth? xs n
#guard nth? [10, 20, 30] 1 = some 20
#guard nth? [10, 20, 30] 3 = none

def last? {a' : Type} : List a' -> Option a'
  | [] => none
  | [x] => some x
  | _ :: xs => last? xs
#guard last? [1, 2, 3] = some 3

def take {a' : Type} : Nat -> List a' -> List a'
  | 0, _ => []
  | _, [] => []
  | n + 1, x :: xs => x :: take n xs
#guard take 2 [1, 2, 3] = [1, 2]

def flatten {a' : Type} : List (List a') -> List a'
  | [] => []
  | xs :: xss => append xs (flatten xss)
#guard flatten [[1], [2, 3], []] = [1, 2, 3]

def map {a' b' : Type} : (a' -> b') -> List a' -> List b'
  | _, [] => []
  | f, x :: xs => f x :: map f xs
#guard map (· * 2) [1, 2, 3] = [2, 4, 6]

def filter {a' : Type} : (a' -> Bool) -> List a' -> List a'
  | _, [] => []
  | p, x :: xs => if p x then x :: filter p xs else filter p xs
#guard filter (· % 2 == 0) [1, 2, 3, 4] = [2, 4]

def foldr {a' b' : Type} : (a' -> b' -> b') -> b' -> List a' -> b'
  | _, init, [] => init
  | f, init, x :: xs => f x (foldr f init xs)
#guard foldr (· + ·) 0 [1, 2, 3] = 6

def zip {a' b' : Type} : List a' -> List b' -> List (a' × b')
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => (x, y) :: zip xs ys
#guard zip [1, 2] ["a", "b", "c"] = [(1, "a"), (2, "b")]

def assoc? {k v : Type} [BEq k] : k -> List (k × v) -> Option v
  | _, [] => none
  | k, (k', v) :: rest => if k' == k then some v else assoc? k rest
#guard assoc? "b" [("a", 1), ("b", 2)] = some 2

end Lists
