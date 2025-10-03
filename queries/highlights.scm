;{{==Keyword=====================================

"return" @keyword.return

["break" "continue" "local" ";"] @keyword

(increment "++" @operator.assignment)

(decrement "--" @operator.assignment)

(function_declaration "fn" @keyword.function)

(function_statement "fn" @keyword.function)

(function_definition "fn" @keyword.function)

(function_definition (parameters "|" @keyword.function))

(class_declaration ["class" "inherits"] @keyword.class)

(class_statement ["class" "inherits"] @keyword.class)

(class_definition ["class" "inherits"] @keyword.class)

"inherits" @error

(do_while_statement ["do" "while"] @repeat)

(while_statement "while" @repeat)

(for_statement "for" @repeat)

(foreach_statement ["foreach" "in"] @repeat)

"in" @error

(if_statement ["if" "else"] @conditional)

"else" @error

(switch_statement "switch" @conditional)

(switch_case "case" @label)

(default_case "default" @label)

["case" "default"] @error

(method "fn" @keyword.function)

;}{=Function=====================================

(parameters (identifier) @variable.parameter)

(variable_declaration
  (variable_list . name: (identifier) @function)
  (expression_list . value: (function_definition)))
      
(function_declaration name: (identifier) @function)

(function_statement
  name: [
    (identifier) @function
    (dot_index_expression
      field: (identifier) @function)
  ])

(assignment_statement
  (variable_list .
    name: [
      (identifier) @function
      (dot_index_expression
        field: (identifier) @function)
    ])
  (expression_list . value: (function_definition)))

(table_constructor
  (field
    name: (identifier) @function
    value: (function_definition)))

(function_call
  name: [
    (identifier) @function.call
    (dot_index_expression field: (identifier) @function.call)
  ])

(method name: (identifier) @function)

(metafield
  field: (identifier) @function
  value: (metamethod))

(function_call
  (identifier) @function.builtin
  (#any-of? @function.builtin
    "clone" "error" "assert" "gc" "load" "loadfile" "runfile"
    "getmetatable" "setmetatable" "unwrapmethod" "getmethods"
    "setmethods" "nextfield" "fields" "indices" "pcall" "xpcall"
    "print" "printf" "warn" "len" "rawequal" "rawget" "rawset"
    "getargs" "tonum" "tostr" "typeof" "getclass" "getsuper" "range"))

;}{=Variable=====================================

(identifier) @variable

((identifier) @variable.builtin
  (#any-of? @variable.builtin
    "__ENV" "__G" "__VERSION" "__POSIX" "__WINDOWS"))

(variable_list
  (attribute
    "<" @punctuation.bracket
    (identifier) @attribute
    ">" @punctuation.bracket))

(method
  parameters: (parameters
    (identifier) @variable.builtin
    (#eq? @variable.builtin "self")) ; when first parameter is "self"
  body: (_
    (identifier) @variable.builtin
    (#eq? @variable.builtin "self")
    (#not-has-parent? @variable.builtin dot_index_expression)))

(method
  parameters: (parameters) @name
    (#not-match? @name "self") ; when there is no "self" parameter
  body: (_
    (identifier) @variable.builtin
    (#eq? @variable.builtin "self")
    (#not-has-parent? @variable.builtin dot_index_expression)))

(metafield
  value: (metamethod
    parameters: (parameters
      first: (identifier) @variable.builtin
      (#eq? @variable.builtin "self")) ; when first parameter is "self"
    body: (_ 
      (identifier) @variable.builtin
      (#eq? @variable.builtin "self")
      (#not-has-parent? @variable.builtin dot_index_expresion))))

(metafield
  value: (metamethod
    parameters: (identifier) @name
      (#not-match? @name "\\bself\\b") ; when there is no "self" parameter
    body: (_
      (identifier) @variable.builtin
      (#eq? @variable.builtin "self")
      (#not-has-parent? @variable.builtin dot_index_expression))))

;}{=List=========================================

(list_constructor ["[" "]"] @constructor)

;}{=Table========================================

(field name: (identifier) @field)

(dot_index_expression field: (identifier) @field)

(table_constructor ["{" "}"] @constructor)

(table_constructor
  (field
    name: (identifier) @function
    value: (function_definition)))

;}{=Class========================================

(class_declaration name: (identifier) @function)

(class_declaration
  superclass: [
    (identifier) @function
    (dot_index_expression
      field: (identifier) @function)
  ])

(class_statement
  name: [
    (identifier) @function
    (dot_index_expression
      field: (identifier) @function)
  ])

(method body: (_ (super) @keyword))

(metafield
  field: (identifier) @function.meta
  (#any-of? @function.meta
    "__getidx" "__setidx" "__gc" "__close" "__call" "__init" 
    "__concat" "__mod" "__pow" "__add" "__sub" "__mul" "__div" 
    "__shl" "__shr" "__band" "__bor" "__bxor" "__unm" "__bnot" 
    "__eq" "__lt" "__le" "__name" ))

(metafield
  field: (identifier) @function
  value: (metafield))

(metafield
  field: (identifier) @function
  value: (metamethod
    body: (_ (super) @keyword)))

(super) @error

;}{=Operator=====================================

(assignment "=" @operator.assignment)

(metafield "=" @operator.assignment)

(compound_assignment
  ["+=" "-=" "*=" "/=" "//=" "**="
   "%=" "&=" "|=" "^=" ">>=" "<<=" "..="] @operator.assignment)

(binary_expression operator: _ @operator)

(unary_expression operator: _ @operator)

["and" "or"] @keyword.operator

;}{=Punctuation==================================

[";" "," "."] @punctuation.delimiter

;}{=Bracket======================================

["(" ")" "[" "]" "{" "}"] @punctuation.bracket

;}{=Constant=====================================

((identifier) @constant (#match? @constant "^[A-Z][A-Z_0-9]*$"))

(vararg_expression) @constant

(nil) @constant.builtin

[(false) (true)] @boolean

;}{==Other=======================================

(comment) @comment

[(number) (char)] @number

(string) @string

(escape_sequence) @string.escape

;}}==============================================
