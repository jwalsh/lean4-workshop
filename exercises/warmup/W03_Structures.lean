/-!
# W03: Structures (FPIL 1.4)

Run:   lean exercises/warmup/W03_Structures.lean

`Float` equality is not exact, so the test checks the distance is
within 1e-9 of the expected value rather than equal to it.
-/

structure Point where
  x : Float
  y : Float
deriving Repr

-- Euclidean distance.
def Point.dist (p q : Point) : Float := sorry
#guard (Point.dist ⟨0, 0⟩ ⟨3, 4⟩ - 5.0).abs < 1e-9
