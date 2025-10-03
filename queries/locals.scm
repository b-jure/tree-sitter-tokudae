;{{==Scope=======================================

[
  (chunk)
  (block_statement)
  (function_declaration)
  (function_statement)
  (function_definition)
  (class_body)
] @local.scope

;}{=Definition===================================

(variable_declaration
  (variable_list
    (identifier) @local.definition))

(function_declaration
  name: (identifier) @local.definition)

(class_declaration
  name: (identifier) @local.definition)

(foreach_statement
  (variable_list
    (identifier) @local.definition))

(parameters (identifier) @local.definition)

;}{=Reference====================================

(identifier) @local.reference

;}}==============================================
