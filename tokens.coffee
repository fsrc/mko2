_ = require("lodash")

TOK =
  DEL: # Delimiters
    id:"DEL"
    def:(c) -> _.contains(['(',')'], c)
    end:[]
    incl:false
    exto:null
  EOL: # End Of Line
    id:"EOL"
    def:(c) -> _.contains(['\n'], c)
    end:[]
    incl:false
    exto:null
  EOF: # End Of File
    id:"EOF"
    def:(c) -> c == null
    end:[]
    incl:false
    exto:null
  INT: # Integers
    id:"INT"
    def:(c) -> _.contains(['0','1','2','3','4','5',
                           '6','7','8','9'], c)
    incl:false
    end:[]
    exto:"NUM"
  NUM: # Decimals
    id: "NUM"
    def: (c) -> _.contains(['0','1','2','3','4',
                            '5','6','7','8','9','.'], c)
    incl:false
    end:[]
    exto:null
  COM: # Comment
    id:"COM"
    def:(c) -> _.contains([';'], c)
    incl:false
    exto:null
  SPACE: # Blank space
    id:"SPACE"
    def:(c) -> _.contains([' ', '\t'], c)
    incl:false
    exto:null
  STR: # Strings
    id: "STR"
    def: (c) -> c == '"'
    incl:true # Eats end token
    exto:null
  IDENT: # Identifier
    id:"IDENT"
    incl:false
    exto:null

TOK.COM.end   = [TOK.EOL.id, TOK.EOF.id]
TOK.STR.end   = [TOK.EOF.id, TOK.STR.id]
TOK.IDENT.end = [TOK.DEL.id, TOK.EOL.id,
                 TOK.EOF.id, TOK.SPACE.id]
TOK.SPACE.end = [TOK.DEL.id, TOK.EOL.id,
                 TOK.EOF.id, TOK.COM.id,
                 TOK.INT.id, TOK.NUM.id,
                 TOK.STR.id, TOK.IDENT.id]
TOK.IDENT.def = (c) ->
  not TOK.DEL.def(c) and
  not TOK.SPACE.def(c) and
  not TOK.INT.def(c) and
  not TOK.NUM.def(c) and
  not TOK.STR.def(c) and
  not TOK.COM.def(c) and
  not TOK.EOL.def(c) and
  not TOK.EOF.def(c)

TOK.ONE_CHAR_TOKENS = [
  TOK.EOL.id,
  TOK.EOF.id,
  TOK.DEL.id
]

TOK.LONG_TOKENS = [
  TOK.SPACE.id,
  TOK.COM.id,
  TOK.INT.id,
  TOK.NUM.id,
  TOK.STR.id
]

module.exports = TOK
