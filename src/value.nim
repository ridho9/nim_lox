type
  Value* = float64
  ValueArray* = seq[Value]

proc print*(value: Value) =
  stdout.write $(value)