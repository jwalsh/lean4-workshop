/-!
# W10: A first proof (FPIL 3, 9)

Run:   lean exercises/warmup/W10_FirstProof.lean

Paste your `myReverse` from W05 over the first `sorry`; the theorem is
about that definition, so the proof depends on how you wrote it.
-/

def myReverse {α : Type} : List α → List α := sorry
#guard myReverse [1, 2, 3] = [3, 2, 1]

-- Induction on `xs`. Useful simp lemmas: `List.length_append`,
-- `List.length_cons`, plus your own `myReverse` equations.
theorem myReverse_length {α : Type} (xs : List α) :
    (myReverse xs).length = xs.length := by
  sorry
