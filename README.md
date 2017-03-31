# ahk brainfuck Interpreter

another brainfuck interpreter on Autohotkey`(1.1.22.09)`

## intro

brainfuck is an extremely minimal Turing-complete programming language with just 8 commands.

Any character not `><+-.,[]` is ignored.

Brainfuck is represented by an array with 30,000 cells initialized to zero
and a data pointer pointing at the current cell.

  > There are eight commands:  
  > `+` : Increments the value at the current cell by one.  
  > `-` : Decrements the value at the current cell by one.  
  > `>` : Moves the data pointer to the next cell (cell on the right).  
  > `<` : Moves the data pointer to the previous cell (cell on the left).  
  > `.` : Prints the ASCII value at the current cell (i.e. 65 = 'A').  
  > `,` : Reads a single input character into the current cell.  
  > `[` : If the value at the current cell is zero, skips to the corresponding ] .  
  > Otherwise, move to the next instruction.  
  > `]` : If the value at the current cell is zero, move to the next instruction. 
  > Otherwise, move backwards in the instructions to the corresponding [ .  
  
## USAGE

`interpreter.ahk helloworld.bf`

or directly drop .bf file on the script if support.
