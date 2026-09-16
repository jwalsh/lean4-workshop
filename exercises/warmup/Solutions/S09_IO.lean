/-! Solution to W09.  Test: lean --run S09_IO.lean < S09_IO.lean

Counts words by scanning characters, which avoids the `String.split`
API that changed between Lean releases.
-/

def countWords (s : String) : Nat := Id.run do
  let mut n := 0
  let mut inWord := false
  for c in s.toList do
    if c.isWhitespace then
      inWord := false
    else if !inWord then
      inWord := true
      n := n + 1
  return n

def main : IO Unit := do
  let stdin ← IO.getStdin
  let mut lines := 0
  let mut words := 0
  repeat
    let line ← stdin.getLine
    if line.isEmpty then break
    lines := lines + 1
    words := words + countWords line
  IO.println s!"{lines} {words}"
