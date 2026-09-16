/-! Solution to W02. -/

def fact : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * fact n
#guard fact 5 = 120

def fib (n : Nat) : Nat :=
  go n 0 1
where
  go : Nat → Nat → Nat → Nat
    | 0, a, _ => a
    | k + 1, a, b => go k b (a + b)
#guard fib 0 = 0
#guard fib 10 = 55
#guard fib 50 = 12586269025
