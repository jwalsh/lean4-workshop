/-!
# W07: Termination (FPIL 10)

Run:   lean exercises/warmup/W07_Termination.lean

This file compiles as given. The exercise is to remove `partial`: Lean
will then reject the definition until you add `termination_by` and, if
needed, `decreasing_by` after the body. The `h` binding is unused now
but is what the termination proof will need.
-/

partial def myGcd (a b : Nat) : Nat :=
  if h : b = 0 then a else myGcd b (a % b)
#guard myGcd 48 18 = 6
#guard myGcd 17 5 = 1
