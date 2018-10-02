import strformat
import value

type
  OpCode* = enum
    OP_RETURN,
    OP_CONST,
    OP_CONST_LONG,
  
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
  var c = this.add_const value

  if c <= high(uint8).int:
    this.write(OP_CONST, line)
    this.write(c, line)
  else:
    # TODO: Generate OP_CONST_LONG
    this.write(OP_CONST_LONG, line)
    this.write(c.mod 0x100, line)
    c = c.div 0x100
    this.write(c.mod 0x100, line)
    c = c.div 0x100
    this.write(c.mod 0x100, line)
    echo "Too many const in chunk"

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

proc const_long_inst (this: Chunk, name: string, offset: int): int =
  let c =
    this.code[offset + 1].int +
    this.code[offset + 2].int * 0x100 +
    this.code[offset + 3].int * 0x10000
  let v = this.constants[int(c)]

  stdout.write &"{name:<16s} {c:4} '"
  v.print()
  stdout.write "'\n"

  result = offset + 4

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
    of OP_CONST_LONG:
      result = this.const_long_inst("OP_CONST_LONG", offset)

  except:
    stdout.write &"Unknown opcode {this.code[offset]}\n"
    result = offset + 1
  
proc disassemble* (this: Chunk, name: string) =
  echo &"== {name} =="

  var i = 0
  while i < this.code.len:
    i = this.disassemble_inst(i)

  stdout.flushFile
