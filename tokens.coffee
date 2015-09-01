_ = require("lodash")

defDEL   = (c) -> _.contains(['(',')'], c)
defEOL   = (c) -> _.contains(['\n'], c)
defEOF   = (c) -> c == null
defINT   = (c) -> _.contains(['0','1','2','3','4','5',
                              '6','7','8','9'], c)
defNUM   = (c) -> _.contains(['0','1','2','3','4',
                              '5','6','7','8','9','.'], c)
defCOM   = (c) -> _.contains([';'], c)
defSPACE = (c) -> _.contains([' ', '\t'], c)
defSTR   = (c) -> c == '"'
defIDENT = (c) ->
  not defDEL(c) and
  not defSPACE(c) and
  not defINT(c) and
  not defNUM(c) and
  not defSTR(c) and
  not defCOM(c) and
  not defEOL(c) and
  not defEOF(c)


##################################################################
# Rules Explanation
# NAME:   Name and ID of token
#   def:  Function that tests if a character could start the token
#         or be a part of the token.
#   end:  What tokens that would end this token.
#   incl: If true, means that the tokenizer should eat the ending
#         token and include it in this token.
#   exto: Defines that this token can be morphed into another token
#   onec: True if it's a single character token
#   use:  True if it's useful in parsing. Space, comments and such
#         don't add any meaning to the code.


# Rules
def =
  DEL    : # Delimiters
    def  : defDEL
    end  : []
    incl : false
    exto : null
    onec : true
    use  : true
  EOL    : # End Of Line
    def  : defEOL
    end  : []
    incl : false
    exto : null
    onec : true
    use  : false
  EOF    : # End Of File
    def  : defEOF
    end  : []
    incl : false
    exto : null
    onec : true
    use  : false
  INT    : # Integers
    def  : defINT
    incl : false
    end  : []
    exto : "NUM"
    onec : false
    use  : true
  NUM    : # Decimals
    def  : defNUM
    incl : false
    end  : []
    exto : null
    onec : false
    use  : true
  COM    : # Comment
    def  : defCOM
    incl : false
    end  : ["EOL", "EOF"]
    exto : null
    onec : false
    use  : false
  SPACE  : # Blank space
    def  : defSPACE
    incl : false
    end  : ["DEL", "COM", "INT", "NUM", "STR", "IDENT", "EOL", "EOF"]
    exto : null
    onec : false
    use  : false
  STR    : # Strings
    def  : defSTR
    incl : true # Eats end token
    end  : ["EOL", "EOF"]
    exto : null
    onec : false
    use  : true
  IDENT  : # Identifier
    def  : defIDENT
    incl : false
    end  : ["DEL", "SPACE", "EOL", "EOF"]
    exto : null
    onec : false
    use  : true



# Adapt the rules to the runtime format
TOK = _.mapValues(def, (value, key) ->
  id:key
  def:value.def
  end:value.end
  incl:value.incl
  exto:value.exto)

TOK.ONE_CHAR_TOKENS = _(def)
  .map((value, key) -> id:key, onec:value.onec)
  .filter((value) -> value.onec)
  .pluck("id")
  .value()

TOK.LONG_TOKENS = _(def)
  .map((value, key) -> id:key, onec:value.onec)
  .filter((value) -> !value.onec)
  .pluck("id")
  .value()

TOK.USELESS_TOKENS = _(def)
  .map((value, key) -> id:key, use:value.use)
  .filter((value) -> !value.use)
  .pluck("id")
  .value()


module.exports = TOK
