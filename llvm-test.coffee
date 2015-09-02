llvm = require("llvm2")

builder = new llvm.Builder()
module = new llvm.Module("TestModule")
myfun = module.addFunction("myfun", new llvm.FunctionType(
  llvm.Library.LLVMInt64Type(),
  [llvm.Library.LLVMInt64Type(), llvm.Library.LLVMInt64Type()], false
))
entry = myfun.appendBasicBlock("entry")
builder.positionAtEnd(entry)
tmp = builder.buildAdd(myfun.getParam(0), myfun.getParam(1), "tmp")
builder.buildRet(tmp)

module.dump()
