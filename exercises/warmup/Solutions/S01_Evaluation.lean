/-! Solution to W01. -/

#eval 2 ^ 10
#eval "Maverick".length
#check fun (n : Nat) => n + 1
#check @List.map

def ex1 : List Nat := [2, 3, 5]
#guard ex1.length = 3 ∧ ex1.sum = 10
