/-! Solution to W08. -/

def sumSquares (n : Nat) : Nat := Id.run do
  let mut acc := 0
  for i in [1:n+1] do
    acc := acc + i * i
  return acc
#guard sumSquares 3 = 14

def primesBelow (n : Nat) : Array Nat := Id.run do
  let mut sieve : Array Bool := Array.replicate n true
  let mut primes := #[]
  for i in [2:n] do
    if sieve[i]! then
      primes := primes.push i
      let mut j := i * i
      while j < n do
        sieve := sieve.set! j false
        j := j + i
  return primes
#guard primesBelow 30 = #[2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
