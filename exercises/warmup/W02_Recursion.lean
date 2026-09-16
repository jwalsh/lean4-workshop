/-!
# W02: Functions, pattern matching, structural recursion (FPIL 1.3, 1.5)

Run:   lean exercises/warmup/W02_Recursion.lean

`fact` is given as a worked example of structural recursion. Write `fib`.
-/

def fact : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * fact n
#guard fact 5 = 120

-- Linear-time Fibonacci. Use an accumulator pair; a naive double
-- recursion will not finish `fib 50` in reasonable time.
def fib (n : Nat) : Nat := sorry
#guard fib 0 = 0
#guard fib 10 = 55
#guard fib 50 = 12586269025
