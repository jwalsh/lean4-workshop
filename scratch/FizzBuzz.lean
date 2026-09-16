def fizzbuzz (n : Nat) : String :=
if n % 15 == 0 then "FizzBuzz"
else if n % 3 == 0 then "Fizz"
else if n % 5 == 0 then "Buzz"
else toString n

#guard fizzbuzz 15 = "FizzBuzz"
#guard fizzbuzz 9 = "Buzz"
#guard fizzbuzz 7 = "7"

def main : IO Unit :=
for i in [1:16] do
IO.println (fizzbuzz i)
