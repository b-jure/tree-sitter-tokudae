;{{==Ignore======================================

["case" "default" "in" "inherits" "else"] @ignore

["," "." "?"] @ignore

["{" "}"] @ignore

(super) @ignore

;}{==Separator===================================

"::" @preproc

;}{==Keyword=====================================

["break" "continue" "local" ";"] @keyword

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

(if_statement "if" @conditional)

(else_statement "else" @conditional)

(switch_statement "switch" @conditional)

(switch_case "case" @label)

(default_case "default" @label)

(method "fn" @keyword.function)

(function_definition
  parameters: (parameters "|" @keyword.function))

;}{=Variable=====================================

(identifier) @variable

((identifier) @variable.builtin
  (#any-of? @variable.builtin
    "__ENV" "__VERSION" "__POSIX" "__WINDOWS"))

((identifier) @module.builtin
  (#any-of? @module.builtin
    "__G" "debug" "io" "math" "os" "package" "string" "reg" "list" "utf8" "co"))

(parameters (identifier) @variable.parameter)

((identifier) @variable.parameter.builtin
  (#eq? @variable.parameter.builtin "self")
  (#has-ancestor? @variable.parameter.builtin function_definition)
  (#has-ancestor? @variable.parameter.builtin metafield))

((identifier) @variable.parameter.builtin
  (#eq? @variable.parameter.builtin "self")
  (#has-ancestor? @variable.parameter.builtin method))

(variable_list
  (attribute
    "<" @punctuation.bracket
    (identifier) @attribute
    ">" @punctuation.bracket))

;}{=Punctuation==================================

(arguments "," @punctuation.delimiter)

(parameters "," @punctuation.delimiter)

(expression_list "," @punctuation.delimiter)

(variable_list "," @punctuation.delimiter)

(table_constructor [";" ","] @punctuation.delimiter)

(list_constructor [";" ","] @punctuation.delimiter)

(dot_index_expression "." @punctuation.delimiter)

;}{=Bracket======================================

["(" ")"] @punctuation.bracket

(bracket_index_expression ["[" "]"] @punctuation.bracket)

;}{=List=========================================

(list_constructor ["[" "]"] @constructor)

;}{=Table========================================

(field name: (identifier) @property)

(dot_index_expression field: (identifier) @variable.member)

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

(function_call "?" @operator)

["and" "or"] @keyword.operator

;}{=Constant=====================================

((identifier) @constant (#match? @constant "^[A-Z][A-Z_0-9]*$"))

(vararg_expression) @constant

(nil) @constant.builtin

[(false) (true)] @boolean

;}{=Class========================================

(variable_declaration
  (assignment
    (variable_list . name: (identifier) @type)
    (expression_list . value: (class_definition))))

(class_declaration name: (identifier) @type)

(class_declaration
  superclass: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
  ])

(class_statement
  name: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
  ])

(class_definition
  superclass: [
    (identifier) @type
    (dot_index_expression
      field: (identifier) @type)
  ])

(assignment_statement
  (assignment
    (variable_list .
      name: [
        (identifier) @type
        (dot_index_expression
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

(variable_declaration
  (assignment
    (variable_list . name: (identifier) @function)
    (expression_list . value: (function_definition))))
      
(function_declaration name: (identifier) @function)

(function_statement
  name: [
    (identifier) @function
    (dot_index_expression
      field: (identifier) @function)
  ])

(assignment_statement
  (assignment
    (variable_list .
      name: [
        (identifier) @function
        (dot_index_expression
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
  ])

(final_call
  (identifier) @function.builtin
  (#any-of? @function.builtin
    "clone" "error" "assert" "gc" "load" "loadfile" "runfile"
    "getmetatable" "setmetatable" "unwrapmethod" "getmethods"
    "setmethods" "nextfield" "fields" "indices" "pcall" "xpcall"
    "print" "printf" "warn" "len" "rawequal" "rawget" "rawset"
    "getargs" "tonum" "tostr" "typeof" "getclass" "getsuper" "range"))

;}{==Other=======================================

(comment) @comment @spell

(char) @character

(number) @number

(string) @string

(escape_sequence) @string.escape

(final_call
  name: (dot_index_expression
    field: (identifier) @_method
    (#any-of? @_method "find" "match" "gmatch" "gsub"))
  arguments: (arguments . (_) . (string
      content: (string_content) @string.regexp)))

;}}==============================================


