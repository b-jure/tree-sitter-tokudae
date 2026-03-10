;{{==Ignore======================================

["case" "default" "in" "inherits" "else"] @ignore
["," "."] @ignore
["{" "}"] @ignore
(call_check_symbol) @ignore
(raw_access_symbol) @ignore
(super) @ignore

;}{==Separator===================================

"::" @preproc

;}{==Keyword=====================================

["break" "continue" "local" "global" ";"] @keyword

(return_statement "return" @keyword.return)

(function_declaration "fn" @keyword.function)

(function_statement "fn" @keyword.function)

(function_definition "fn" @keyword.function)

(class_declaration ["class" "inherits"] @keyword.class)

(class_statement ["class" "inherits"] @keyword.class)

(class_definition ["class" "inherits"] @keyword.class)

(do_while_statement ["do" "while"] @repeat)

(while_statement "while" @repeat)

(for_statement "for" @repeat)

(foreach_statement ["foreach" "in"] @repeat)

(loop_statement "loop" @repeat)

(if_statement "if" @keyword.conditional)

(else_statement "else" @keyword.conditional)

(switch_statement "switch" @keyword.conditional)

(switch_case "case" @label)

(default_case "default" @label)

(method "fn" @keyword.function)

(function_definition
  parameters: (parameters "|" @keyword.function))

;}{=Variable=====================================

(identifier) @variable

((identifier) @variable.builtin
  (#any-of? @variable.builtin
    "__ENV" "__VERSION" "__POSIX" "__WINDOWS" "__G"))

((identifier) @module.builtin
  (#any-of? @module.builtin
    "debug" "io" "math" "os" "package" "string" "reg" "list" "utf8"
    "table" "co" "json"))

(parameters (identifier) @variable.parameter)

(parameters
  first: (identifier) @variable.parameter.builtin
  (#eq? @variable.parameter.builtin "self"))

(parameters type: (identifier) @type.builtin)
(parameters ["|" "?"] @keyword)

(attribute
  "<" @punctuation.bracket
  (identifier) @attribute.builtin
  ">" @punctuation.bracket)

;}{=Punctuation==================================

(arguments "," @punctuation.delimiter)

(parameters "," @punctuation.delimiter)

(expression_list "," @punctuation.delimiter)

(variable_list "," @punctuation.delimiter)

(table_constructor [";" ","] @punctuation.delimiter)

(list_constructor [";" ","] @punctuation.delimiter)

(dot_index_expression "." @punctuation.delimiter)

(raw_access_symbol) @punctuation.delimiter

;}{=Bracket======================================

["(" ")"] @punctuation.bracket

(bracket_index_expression ["[" "]"] @punctuation.bracket)

(arrow_index_expression field: (index_field ["[" "]"] @punctuation.bracket))

;}{=List=========================================

(list_constructor ["[" "]"] @constructor)

;}{=Table========================================

(dot_index_expression field: (identifier) @variable.member)

(arrow_index_expression
  (raw_access_symbol)
  field: (identifier) @variable.member)

(table_constructor ["{" "}"] @constructor)

;}{=Operator=====================================

(increment "++" @operator.assignment)

(decrement "--" @operator.assignment)

(assignment "=" @operator.assignment)

(metafield "=" @operator.assignment)

(field "=" @operator.assignment)

(compound_assignment
  ["+=" "-=" "*=" "/=" "//=" "**="
   "%=" "&=" "|=" "^=" ">>=" "<<=" "..="] @operator.assignment)

(binary_expression operator: _ @operator)

(unary_expression operator: _ @operator)

(call_check_symbol) @operator

["and" "or"] @keyword.operator

(table_constructor (field ["[" "]"] @operator))

; this must be after '*' operator
(global_variable_declaration glob: "*" @variable.builtin)

;}{=Constant=====================================

((identifier) @constant (#match? @constant "^[A-Z][A-Z_0-9]*$"))

; override identifier constants
(field name: (identifier) @property)

(vararg_expression) @constant

; override regular vararg expression
(vararg
  (vararg_expression) @variable.parameter
  vararg_list: (identifier) @variable.parameter)

(nil) @constant.builtin

[(false) (true)] @boolean

;}{=Class========================================

(local_variable_declaration
  (assignment
    (variable_list . name: (identifier) @type)
    (expression_list . value: (class_definition))))

(global_variable_declaration
  (assignment
    (variable_list . name: (identifier) @type)
    (expression_list . value: (class_definition))))

(class_declaration name: (identifier) @type)

(class_declaration
  superclass: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
    (arrow_index_expression
      field: (identifier) @type)
  ])

(class_statement
  name: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
    (arrow_index_expression
      field: (identifier) @type)
  ])

(class_statement
  superclass: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
    (arrow_index_expression
      field: (identifier) @type)
  ])

(class_definition
  superclass: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
    (arrow_index_expression
      field: (identifier) @type)
  ])

(assignment_statement
  (assignment
    (variable_list .
      name: [
        (identifier) @type
        (dot_index_expression
          field: (identifier) @type)
        (arrow_index_expression
          field: (identifier) @type)
      ])
    (expression_list . value: (class_definition))))

(table_constructor
  (field
    name: (identifier) @type
    value: (class_definition)))

(metafield
  field: (identifier) @type
  value: (class_definition))

((super) @keyword
  (#has-ancestor? @keyword function_definition)
  (#has-ancestor? @keyword metafield))

((super) @keyword
  (#has-ancestor? @keyword method))

;}{=Function=====================================

(local_variable_declaration
  (assignment
    (variable_list . name: (identifier) @function)
    (expression_list . value: (function_definition))))

(global_variable_declaration
  (assignment
    (variable_list . name: (identifier) @function)
    (expression_list . value: (function_definition))))
      
(function_declaration . name: (identifier) @function)

(function_statement .
  name: [
    (identifier) @function
    (dot_index_expression
      field: (identifier) @function)
    (arrow_index_expression
      field: (identifier) @function)
  ])

(assignment_statement
  (assignment
    (variable_list .
      name: [
        (identifier) @function
        (dot_index_expression
          field: (identifier) @function)
        (arrow_index_expression
          field: (identifier) @function)
      ])
    (expression_list . value: (function_definition))))

(table_constructor
  (field
    name: (identifier) @function
    value: (function_definition)))

(method name: (identifier) @function)

(metafield
  field: (identifier) @function
  value: (function_definition))

(metafield
  field: (identifier) @function.builtin
  (#any-of? @function.builtin
    "__getidx" "__setidx" "__gc" "__close" "__call" "__init" 
    "__concat" "__mod" "__pow" "__add" "__sub" "__mul" "__div" "__idiv"
    "__shl" "__shr" "__band" "__bor" "__bxor" "__unm" "__bnot" 
    "__eq" "__lt" "__le" "__name" ))

(final_call
  name: [
    (identifier) @function.call
    (dot_index_expression field: (identifier) @function.call)
    (arrow_index_expression field: (identifier) @function.call)
  ])

(final_call
  (identifier) @function.builtin
  (#any-of? @function.builtin
    "clone" "error" "assert" "gc" "load" "loadfile" "runfile"
    "getmetatable" "setmetatable" "unwrapmethod" "getmethods"
    "setmethods" "nextfield" "fields" "indices" "pcall" "xpcall"
    "print" "printf" "warn" "len" "rawequal" "rawget" "rawset"
    "getargs" "tonum" "tostr" "type" "getclass" "getsuper" "range"
    "repeat"))

;}{==Other=======================================

(comment) @comment @spell

(char) @character

(number) @number

(string) @string

(escape_sequence) @string.escape

(final_call
  name: [
    (dot_index_expression
      field: (identifier) @function.method
      (#any-of? @function.method "find" "match" "gmatch" "gsub"))
    (arrow_index_expression
      field: (identifier) @function.method
      (#any-of? @function.method "find" "match" "gmatch" "gsub"))
  ]
  arguments: (arguments . (_) . (string
      content: (string_content) @string.regexp)))

;}}==============================================


