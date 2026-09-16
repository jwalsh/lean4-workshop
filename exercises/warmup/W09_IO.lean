/-!
# W09: IO and do-notation (FPIL 2)

Run:   lean --run exercises/warmup/W09_IO.lean < exercises/warmup/W09_IO.lean

There is no `#guard` here: the test is running the program on a file
and comparing with `wc -lw`. On this file the expected output is two
numbers, the line count and the word count.
-/

-- Read stdin to EOF; print line count and whitespace-separated word count.
def main : IO Unit := sorry
