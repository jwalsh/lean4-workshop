/-!
# W08: Mutable state, arrays, loops in `Id.run do` (FPIL 2, 5)

Run:   lean exercises/warmup/W08_MutableState.lean

`sumSquares` is a worked example. Write `primesBelow` the same way.
-/

def sumSquares (n : Nat) : Nat := Id.run do
  let mut acc := 0
  for i in [1:n+1] do
    acc := acc + i * i
  return acc
#guard sumSquares 3 = 14

-- Sieve of Eratosthenes. Use a mutable `Array Bool` and `for`/`while`.
def primesBelow (n : Nat) : Array Nat := sorry
#guard primesBelow 30 = #[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
