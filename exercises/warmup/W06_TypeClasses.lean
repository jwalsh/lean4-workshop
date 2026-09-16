/-!
# W06: Type classes (FPIL 4)

Run:   lean exercises/warmup/W06_TypeClasses.lean

An `instance` is a structure whose fields are the class's methods.
`instance : Add V2 := ⟨fun a b => ...⟩` or `where add a b := ...`
both work.
-/

structure V2 where
  x : Int
  y : Int
deriving Repr, DecidableEq

instance : Add V2 := sorry
instance : ToString V2 := sorry
#guard V2.mk 1 2 + V2.mk 3 4 = V2.mk 4 6
#guard toString (V2.mk 1 2) = "(1, 2)"
