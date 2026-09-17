-- scratch/Euler.lean: Project Euler in Lean. Each problem: a #guard against
-- the small example in the statement, then #eval for the real answer.

namespace Euler

-- #1: sum of all multiples of 3 or 5 below N.
def sumMultiples (limit : Nat) : Nat := sorry 
#guard sumMultiples 10 = 23
#eval sumMultiples 1000
  
-- #2: sum of even-valued Fibonacci terms not exceeding N.
def evenFibSum (limit : Nat) : Nat := sorry
#guard evenFibSum 10 = 10
#eval evenFibSum 4000000

-- #6: (sum 1..N)^2 - sum of squares 1..N.
def sumSquareDiff (n : Nat) : Nat := sorry
#guard sumSquareDiff 10 = 2640
#eval sumSquareDiff 100

-- #16: sum of the digits of 2^N.
def powerDigitSum (n : Nat) : Nat := sorry
#guard powerDigitSum 15 = 26
#eval powerDigitSum 1000

-- #5: smallest positive number divisible by every one of 1..N.
def lcmAll (upTo : Nat) : Nat := sorry
#guard lcmAll 10 = 2520
#eval lcmAll 20

-- #3: largest prime factor of N.
def largestPrimeFactor (n : Nat) : Nat := sorry
#guard largestPrimeFactor 13195 = 29
#eval largestPrimeFactor 600851475143

-- #7: the Nth prime, 1-indexed.
def isPrime (n : Nat) : Bool := sorry
#guard isPrime 2 = True

def nthPrime (n : Nat) : Nat := sorry
#guard nthPrime 6 = 13
#eval nthPrime 10001

