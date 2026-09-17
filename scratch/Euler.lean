-- scratch/Euler.lean: Project Euler in Lean. Each problem: a #guard against
-- the small example in the statement, then #eval for the real answer.

namespace Euler

-- #1: sum of all multiples of 3 or 5 below N.
def sumMultiples (limit : Nat) : Nat :=
  (List.range limit).filter (fun n => n % 3 == 0 || n % 5 == 0) |>.foldl (· + ·) 0 
#guard sumMultiples 10 = 23
#eval sumMultiples 1000
  
-- #2: sum of even-valued Fibonacci terms not exceeding N.
def evenFibSum (limit : Nat) : Nat := Id.run do
  let mut a := 0
  let mut b := 1
  let mut total := 0
  while a <= limit do
    if a % 2 == 0 then total := total + a
    let next := a + b
    a := b
    b := next
  return total
#guard evenFibSum 10 = 10
#eval evenFibSum 4000000

-- #6: (sum 1..N)^2 - sum of squares 1..N.
def sumSquareDiff (n : Nat) : Nat :=
  let s := (List.range (n + 1)).foldl (· + ·) 0
  let sq := (List.range (n + 1)).foldl (fun acc k => acc + k * k) 0
  s * s - sq
#guard sumSquareDiff 10 = 2640
#eval sumSquareDiff 100

-- #16: sum of the digits of 2^N.
def powerDigitSum (n : Nat) : Nat :=
  (Nat.toDigits 10 (2 ^ n)).foldl (fun acc c => acc + (c.toNat - '0'.toNat)) 0
#guard powerDigitSum 15 = 26
#eval powerDigitSum 1000

-- #5: smallest positive number divisible by every one of 1..N.
def lcmAll (upTo : Nat) : Nat :=
  (List.range upTo).map (· + 1) |>.foldl (fun acc n => acc * n / Nat.gcd acc n) 1
#guard lcmAll 10 = 2520
#eval lcmAll 20
#eval lcmAll 42

-- #3: largest prime factor of N.
def largestPrimeFactor (n : Nat) : Nat := Id.run do
  let mut n := n
  let mut factor := 2
  let mut largest := 1
  while factor * factor <= n do
    if n % factor == 0 then
      largest := factor
      while n % factor == 0 do
        n := n / factor
    else
      factor := factor + 1
  if n > 1 then largest := n
  return largest
#guard largestPrimeFactor 13195 = 29
#eval largestPrimeFactor 600851475143
#eval largestPrimeFactor 90210

-- 7 x 11 x 13 = 1001: multiply any 3-digit number by it and it repeats itself
#eval 7 * 11 * 13
#eval 123 * 1001

-- #7: the Nth prime, 1-indexed.
def isPrime (n : Nat) : Bool := Id.run do
  if n < 2 then return false
  let mut i := 2
  while i * i <= n do
    if n % i == 0 then return false
    i := i + 1
  return true
#guard isPrime 2 = true
#eval isPrime 42
#eval isPrime 73

def nthPrime (n : Nat) : Nat := Id.run do
  let mut count := 0
  let mut candidate := 1
  while count < n do
    candidate := candidate + 1
    if isPrime candidate then count := count + 1
  return candidate
#guard nthPrime 6 = 13
#eval nthPrime 10001

