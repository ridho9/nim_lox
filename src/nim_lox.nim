import chunk

when isMainModule:
  var ch = newChunk()
  
  ch.write_const(10, 10)
  ch.write(OP_RETURN, 10)

  ch.disassemble "test chunk"