llvm  = require("llvm3")

# ######################################################################
# Mapping of types
exports.typeMap = typeMap =
  "int-type" : llvm.func.LLVMInt64Type
  "byte-type" : llvm.func.LLVMInt8Type
  "str-type" : llvm.func.LLVMInt8Type
  "bool-type" : llvm.func.LLVMInt1Type

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

