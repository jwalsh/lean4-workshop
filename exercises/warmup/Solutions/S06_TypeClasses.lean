/-! Solution to W06. -/

structure V2 where
  x : Int
  y : Int
deriving Repr, DecidableEq

instance : Add V2 where
  add a b := ⟨a.x + b.x, a.y + b.y⟩

instance : ToString V2 where
  toString v := s!"({v.x}, {v.y})"

#guard V2.mk 1 2 + V2.mk 3 4 = V2.mk 4 6
#guard toString (V2.mk 1 2) = "(1, 2)"
