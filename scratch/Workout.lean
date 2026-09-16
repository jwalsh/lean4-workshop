-- scratch/Workout.lean: signature, body, one #guard, one #eval per problem.
-- To work one, put its body back to `sorry`.

namespace Workout

/-! ## Strings -/

def reverse (s : String) : String :=
  String.mk s.toList.reverse
#guard reverse "hello" = "olleh"
#eval reverse "stressed"

def isPalindrome (s : String) : Bool :=
  let letters := s.toList.filter Char.isAlpha |>.map Char.toLower
  letters == letters.reverse
#guard isPalindrome "Was it a car or a cat I saw?" = true
#eval isPalindrome "Go hang a salami, I'm a lasagna hog."

def isVowel (c : Char) : Bool :=
  "aeiou".contains c.toLower
#guard isVowel 'e' = true
#eval isVowel 'y'

def countVowels (s : String) : Nat :=
  s.toList.filter isVowel |>.length
#guard countVowels "functional" = 4
#eval countVowels "Lean"

def capitalized (s : String) : Bool :=
  match s.toList with
  | c :: _ => c.isUpper
  | [] => false
#guard capitalized "Lean" = true
#eval capitalized "lean"

def pigLatin (word : String) : String :=
  match word.toList with
  | [] => ""
  | c :: rest =>
    if isVowel c then word ++ "way"
    else String.mk rest ++ String.singleton c ++ "ay"
#guard pigLatin "python" = "ythonpay"
#eval pigLatin "apple"

def reverseWords (s : String) : String :=
  s.splitOn " " |>.filter (· ≠ "") |>.reverse |> String.intercalate " "
#guard reverseWords "  hello   world  " = "world hello"
#eval reverseWords "the sky is blue"

def balanced (s : String) : Bool :=
  go s.toList []
where
  go : List Char → List Char → Bool
    | [], stack => stack.isEmpty
    | c :: cs, stack =>
      if c == '(' || c == '[' || c == '{' then go cs (c :: stack)
      else match stack with
        | open_ :: stack' =>
          if (open_ == '(' && c == ')') || (open_ == '[' && c == ']') || (open_ == '{' && c == '}')
          then go cs stack' else false
        | [] => false
#guard balanced "{[(])}" = false
#eval balanced "{{[[(())]]}}"

def insertSorted (c : Char) : List Char → List Char
  | [] => [c]
  | d :: ds => if c ≤ d then c :: d :: ds else d :: insertSorted c ds
#guard insertSorted 'b' ['a', 'c'] = ['a', 'b', 'c']
#eval insertSorted 'z' ['a']

def sortString (s : String) : String :=
  String.mk (s.toList.foldr insertSorted [])
#guard sortString "cba" = "abc"
#eval sortString "lean4"

def roundTrip (path : String) : Bool :=
  let step := fun ((x, y, d) : Int × Int × Nat) (c : Char) =>
    match c with
    | 'F' => match d with
      | 0 => (x, y + 1, d) | 1 => (x + 1, y, d) | 2 => (x, y - 1, d) | _ => (x - 1, y, d)
    | 'L' => (x, y, (d + 3) % 4)
    | 'R' => (x, y, (d + 1) % 4)
    | _ => (x, y, d)
  let (x, y, _) := path.toList.foldl step (0, 0, 0)
  x == 0 && y == 0
#guard roundTrip "RFFRFFRFFRF" = false
#eval roundTrip "FLFLFLF"

/-! ## Lists -/

def firstLast {a' : Type} : List a' -> List a'
  | [] => []
  | [x] => [x, x]
  | x :: xs => match xs.getLast? with
    | some y => [x, y]
    | none => [x, x]
#guard firstLast [1, 2, 3, 4] = [1, 4]
#eval firstLast ["a", "b", "c"]

def largest : List Nat -> Option Nat
  | [] => none
  | x :: xs => some (xs.foldl max x)
#guard largest [3, 9, 2] = some 9
#eval largest ([] : List Nat)

def evenOddSums (xs : List Nat) : Nat × Nat :=
  xs.foldl (fun (e, o) x => if x % 2 == 0 then (e + x, o) else (e, o + x)) (0, 0)
#guard evenOddSums [1, 2, 3, 4, 5] = (6, 9)
#eval evenOddSums [10, 20, 31]

def myZip {a' b' : Type} : List a' -> List b' -> List (a' × b')
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => (x, y) :: myZip xs ys
#guard myZip [1, 2] ["a", "b", "c"] = [(1, "a"), (2, "b")]
#eval myZip ["x", "y"] [true, false]

def mostRepeated (cs : List Char) : Option Char :=
  let count := fun c => cs.filter (· == c) |>.length
  cs.foldl (fun best c =>
    match best with
    | none => some c
    | some b => if count c > count b then some c else best) none
#guard mostRepeated "mississippi".toList = some 'i'
#eval mostRepeated "banana".toList

def twoSum (nums : List Int) (target : Int) : List Nat :=
  go 0 nums
where
  findFrom (j : Nat) (v : Int) : List Int → Option Nat
    | [] => none
    | y :: ys => if y == v then some j else findFrom (j + 1) v ys
  go (i : Nat) : List Int → List Nat
    | [] => []
    | x :: xs => match findFrom (i + 1) (target - x) xs with
      | some j => [i, j]
      | none => go (i + 1) xs
#guard twoSum [2, 7, 11, 15] 9 = [0, 1]
#eval twoSum [3, 2, 4] 6

def mergeSorted : List Int -> List Int -> List Int
  | [], ys => ys
  | xs, [] => xs
  | x :: xs, y :: ys =>
    if x ≤ y then x :: mergeSorted xs (y :: ys) else y :: mergeSorted (x :: xs) ys
#guard mergeSorted [1, 4, 5] [1, 3, 4] = [1, 1, 3, 4, 4, 5]
#eval mergeSorted [1] [0]

def runLength : List Char -> List (Char × Nat)
  | [] => []
  | c :: cs => match runLength cs with
    | (d, n) :: rest => if c == d then (d, n + 1) :: rest else (c, 1) :: (d, n) :: rest
    | [] => [(c, 1)]
#guard runLength "aaabcc".toList = [('a', 3), ('b', 1), ('c', 2)]
#eval runLength "wwwwaaadexxxxxx".toList

def degree (xs : List Nat) : Nat :=
  let indexed := xs.zip (List.range xs.length)
  let stats := xs.eraseDups.map fun v =>
    let idx := indexed.filter (·.1 == v) |>.map (·.2)
    (idx.length, idx.foldl max 0 - idx.foldl min xs.length + 1)
  let deg := stats.foldl (fun m (c, _) => max m c) 0
  stats.filter (·.1 == deg) |>.map (·.2) |>.foldl min xs.length
#guard degree [1, 2, 2, 3, 1] = 2
#eval degree [1, 2, 2, 3, 1, 4, 2]

/-! ## Stacks and accumulators -/

-- Int `/` is Euclidean: -7 / 2 = -4. RPN wants truncation.
def tdiv (a b : Int) : Int :=
  let q : Int := (a.natAbs / b.natAbs : Nat)
  if (a < 0) != (b < 0) then -q else q
#guard tdiv (-7) 2 = -3
#eval (-7 : Int) / 2

def rpn (tokens : List String) : Int :=
  go tokens []
where
  go : List String → List Int → Int
    | [], top :: _ => top
    | [], [] => 0
    | t :: ts, stack =>
      match t, stack with
      | "+", b :: a :: rest => go ts ((a + b) :: rest)
      | "-", b :: a :: rest => go ts ((a - b) :: rest)
      | "*", b :: a :: rest => go ts ((a * b) :: rest)
      | "/", b :: a :: rest => go ts (tdiv a b :: rest)
      | n, _ => go ts (n.toInt! :: stack)
#guard rpn ["7", "-2", "/"] = -3
#eval rpn ["2", "1", "+", "3", "*"]

def runningMax : List Nat -> List Nat
  | [] => []
  | x :: xs => go x xs
where
  go (m : Nat) : List Nat → List Nat
    | [] => [m]
    | y :: ys => m :: go (max m y) ys
#guard runningMax [3, 1, 4, 1, 5] = [3, 3, 4, 4, 5]
#eval runningMax [5, 4, 3]

/-! ## Numbers -/

def fizzbuzz (n : Nat) : String :=
  if n % 15 == 0 then "FizzBuzz"
  else if n % 3 == 0 then "Fizz"
  else if n % 5 == 0 then "Buzz"
  else toString n
#guard fizzbuzz 15 = "FizzBuzz"
#eval (List.range 15).map (fun i => fizzbuzz (i + 1))

-- n / 10 is not structural recursion: termination_by + omega.
def sumDigits (n : Nat) : Nat :=
  if h : n < 10 then n else n % 10 + sumDigits (n / 10)
termination_by n
decreasing_by omega
#guard sumDigits 1234 = 10
#eval sumDigits 9999

def toHex (n : Nat) : String :=
  String.mk (Nat.toDigits 16 n)
#guard toHex 255 = "ff"
#eval toHex 48879

def mean (xs : List Nat) : Float :=
  (xs.foldl (· + ·) 0).toFloat / xs.length.toFloat
#guard mean [1, 2, 3, 4] == 2.5
#eval mean [90, 85, 77]

def isPrime (n : Nat) : Bool :=
  n ≥ 2 && (List.range (n - 2)).all fun i => n % (i + 2) != 0
#guard isPrime 91 = false
#eval (List.range 30).filter isPrime

-- partial: termination unproven.
partial def collatzSteps (n : Nat) : Nat :=
  if n ≤ 1 then 0
  else 1 + collatzSteps (if n % 2 == 0 then n / 2 else 3 * n + 1)
#guard collatzSteps 27 = 111
#eval collatzSteps 97

def coinChange (coins : List Nat) (amount : Nat) : Option Nat := Id.run do
  let mut best : Array (Option Nat) := Array.replicate (amount + 1) none
  best := best.set! 0 (some 0)
  for a in [1:amount + 1] do
    for c in coins do
      if c ≤ a then
        match best[a - c]! with
        | some k =>
          match best[a]! with
          | some cur => if k + 1 < cur then best := best.set! a (some (k + 1))
          | none => best := best.set! a (some (k + 1))
        | none => pure ()
  return best[amount]!
#guard coinChange [1, 2, 5] 11 = some 3
#eval coinChange [2] 3

/-! ## Transforms -/

def shiftLetter (k : Nat) (c : Char) : Char :=
  if c.isLower then Char.ofNat ('a'.toNat + (c.toNat - 'a'.toNat + k) % 26)
  else if c.isUpper then Char.ofNat ('A'.toNat + (c.toNat - 'A'.toNat + k) % 26)
  else c
#guard shiftLetter 1 'z' = 'a'
#eval shiftLetter 13 'N'

def caesar (k : Nat) (s : String) : String :=
  s.map (shiftLetter k)
#guard caesar 3 "xyz" = "abc"
#eval caesar 23 "abc"

def rot13 (s : String) : String :=
  caesar 13 s
#guard rot13 "Hello, World" = "Uryyb, Jbeyq"
#eval rot13 "Uryyb, Jbeyq"

def atbash (s : String) : String :=
  s.map fun c =>
    if c.isLower then Char.ofNat ('a'.toNat + 'z'.toNat - c.toNat)
    else if c.isUpper then Char.ofNat ('A'.toNat + 'Z'.toNat - c.toNat)
    else c
#guard atbash "lean" = "ovzm"
#eval atbash "ovzm"

def hexEncode (s : String) : String :=
  String.mk <| s.toUTF8.toList.foldr (fun b acc =>
    let ds := Nat.toDigits 16 b.toNat
    (if ds.length == 1 then '0' :: ds else ds) ++ acc) []
#guard hexEncode "Lean" = "4c65616e"
#eval hexEncode "hi"

def b64Char (i : Nat) : Char :=
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".toList.getD i '?'
#guard b64Char 26 = 'a'
#eval b64Char 63

def base64Encode (s : String) : String :=
  String.mk (go (s.toUTF8.toList.map (·.toNat)))
where
  go : List Nat → List Char
    | a :: b :: c :: rest =>
      let n := a * 65536 + b * 256 + c
      b64Char (n / 262144) :: b64Char (n / 4096 % 64) :: b64Char (n / 64 % 64) :: b64Char (n % 64) :: go rest
    | [a, b] =>
      let n := a * 65536 + b * 256
      [b64Char (n / 262144), b64Char (n / 4096 % 64), b64Char (n / 64 % 64), '=']
    | [a] =>
      let n := a * 65536
      [b64Char (n / 262144), b64Char (n / 4096 % 64), '=', '=']
    | [] => []
#guard base64Encode "Lean" = "TGVhbg=="
#eval base64Encode "Man"

#eval "Lean" |> rot13 |> base64Encode
#guard ("Lean" |> rot13 |> rot13) = "Lean"

end Workout
