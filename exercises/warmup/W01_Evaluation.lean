/-!
# W01: Evaluation and types (FPIL 1.1–1.2)

Run:   lean exercises/warmup/W01_Evaluation.lean

Replace `sorry`. The `#guard` line is the test: it errors until `ex1`
is correct. The `#eval` and `#check` lines print; that output is
expected, not an error.
-/

#eval 2 ^ 10
#eval "Maverick".length
#check fun (n : Nat) => n + 1
#check @List.map

-- Write a `List Nat` with three elements whose sum is 10.
def ex1 : List Nat := sorry
#guard ex1.length = 3 ∧ ex1.sum = 10
