llvm  = require("llvm2")

# ######################################################################
# Mapping of types
exports.typeMap = typeMap =
  "int-type" : llvm.Library.LLVMInt64Type
  "byte-type" : llvm.Library.LLVMInt8Type
  "str-type" : llvm.Library.LLVMInt8Type
  "bool-type" : llvm.Library.LLVMInt1Type

# ######################################################################
# Mapping of constants
exports.constants = constants =
  INT : (value) ->
    llvm.Library.LLVMConstInt(
      typeMap["int-type"](),
      parseInt(value),
      false)
  STR : (value) ->
    throw "Not implemented"
  BOOL: (value) ->
    throw "Not implemented"

