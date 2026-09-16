/-! Solution to W03. -/

structure Point where
  x : Float
  y : Float
deriving Repr

def Point.dist (p q : Point) : Float :=
  let dx := p.x - q.x
  let dy := p.y - q.y
  Float.sqrt (dx * dx + dy * dy)
#guard (Point.dist ⟨0, 0⟩ ⟨3, 4⟩ - 5.0).abs < 1e-9
