import strformat
import value

type
  OpCode* = enum
    OP_RETURN,
    OP_CONST,
  
  Chunk* = ref object
    code*: seq[uint8]
    constants*: ValueArray
    lines: seq[int]

proc newChunk* (): Chunk =
  result = Chunk()

proc write* (this: Chunk, value: uint8, line: int) =
  this.lines.add line
  this.code.add value

proc write* (this: Chunk, value: OpCode, line: int) =
  this.lines.add line
  this.code.add uint8(value)

proc write* (this: Chunk, value: int, line: int) =
  this.lines.add line
  this.code.add uint8(value)

proc add_const* (this: Chunk, value: Value): int = 
  this.constants.add value
  result = this.constants.len - 1

proc write_const* (this: Chunk, value: Value, line: int) =
  this.write(OP_CONST, line)
  let c = this.add_const value
  this.write(c, line)

proc simple_inst (this: Chunk, name: string, offset: int): int =
  stdout.write name & "\n"
  result = offset + 1

proc const_inst (this: Chunk, name: string, offset: int): int =
  let c = this.code[offset + 1]
  let v = this.constants[int(c)]

  stdout.write &"{name:<16s} {c:4} '"
  v.print()
  stdout.write "'\n"

  result = offset + 2

proc disassemble_inst* (this: Chunk, offset: int): int =
  stdout.write &"{offset:04}  "

  if offset > 0 and this.lines[offset] == this.lines[offset - 1]:
    stdout.write "   | "
  else:
    stdout.write &"{this.lines[offset]:4} "

  try:
    let inst = OpCode(this.code[offset])

    case inst
    of OP_RETURN:
      result = this.simple_inst("OP_RETURN", offset)
    of OP_CONST:
      result = this.const_inst("OP_CONST", offset)

  except:
    stdout.write &"Unknown opcode {this.code[offset]}\n"
    result = offset + 1
  
proc disassemble* (this: Chunk, name: string) =
  echo &"== {name} =="

  var i = 0
  while i < this.code.len:
    i = this.disassemble_inst(i)

  stdout.flushFile
