/-! Solution to W07.

`h : ¬b = 0` is exactly what the termination goal `a % b < b` needs.
Stating the fact with `have` in the else-branch lets the default
`decreasing_tactic` find it; `decreasing_by` is the other route.
-/

def myGcd (a b : Nat) : Nat :=
  if h : b = 0 then a
  else
    have : a % b < b := Nat.mod_lt _ (Nat.pos_of_ne_zero h)
    myGcd b (a % b)
termination_by b
#guard myGcd 48 18 = 6
#guard myGcd 17 5 = 1
