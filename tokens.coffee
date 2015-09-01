_ = require("lodash")

TOK =
  DEL: # Delimiters
    id:"DEL"
    def:(c) -> _.contains(['(',')'], c)
    end:[]
    incl:false
  EOL: # End Of Line
    id:"EOL"
    def:(c) -> _.contains(['\n'], c)
    end:[]
    incl:false
  EOF: # End Of File
    id:"EOF"
    def:(c) -> c == null
    end:[]
    incl:false
  INT: # Integers
    id:"INT"
    def:(c) -> _.contains(['0','1','2','3','4','5','6','7','8','9'], c)
    incl:false
    end:[]
  NUM: # Decimals
    id: "NUM"
    def: (c) -> _.contains(['0','1','2','3','4','5','6','7','8','9','.'], c)
    incl:false
    end:[]
  COM: # Comment
    id:"COM"
    def:(c) -> _.contains(['#'], c)
    incl:false
  SPACE: # Blank space
    id:"SPACE"
    def:(c) -> _.contains([' ', '\t'], c)
    incl:false
  STR: # Strings
    id: "STR"
    def: (c) -> c == '"'
    incl:true # Eats end token
  IDENT: # Identifier
    id:"IDENT"
    incl:false

TOK.COM.end   = [TOK.EOL.id, TOK.EOF.id]
TOK.IDENT.end = [TOK.DEL.id, TOK.EOL.id, TOK.EOF.id, TOK.SPACE.id]
TOK.SPACE.end = [TOK.DEL.id, TOK.EOL.id, TOK.EOF.id, TOK.COM.id, TOK.INT.id, TOK.NUM.id, TOK.STR.id, TOK.IDENT.id]
TOK.STR.end = [TOK.EOF.id, TOK.STR.id]
TOK.IDENT.def = (c) ->
  not TOK.DEL.def(c) and
  not TOK.SPACE.def(c) and
  not TOK.INT.def(c) and
  not TOK.NUM.def(c) and
  not TOK.STR.def(c) and
  not TOK.COM.def(c) and
  not TOK.EOL.def(c) and
  not TOK.EOF.def(c)

module.exports = TOK
