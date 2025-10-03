;{{==Function====================================

(function_declaration name: (identifier) @name) @definition.function

(function_statement
  name: [
    (identifier) @name
    (dot_index_expression
      field: (identifier) @name)
  ]) @definition.function

(assignment
  (variable_list .
    name: [
      (identifier) @name
      (dot_index_expression
        field: (identifier) @name)
    ])
  (expression_list .
    value: (function_definition))) @definition.function

(table_constructor
  (field
    name: (identifier) @name
    value: (function_definition))) @definition.function

(metafield
  field: (identifier) @name
  value: (metamethod)) @definition.function

(method name: (identifier) @name) @definition.method

;}{=Class========================================

(class_declaration name: (identifier) @name) @definition.class

(class_statement
  name: [
    (identifier) @name
    (dot_index_expression
      field: (identifier) @name)
  ]) @definition.class

(assignment
  (variable_list .
    name: [
      (identifier) @name
      (dot_index_expression
        field: (identifier) @name)
    ])
  (expression_list .
    value: (class_definition))) @definition.class

(table_constructor
  (field
    name: (identifier) @name
    value: (class_definition))) @definition.class

(metafield
  field: (identifier) @name
  value: (class_definition)) @definition.class

;}{=Reference====================================

(method
  parameters: (parameters
    first: (identifier) @reference.class
    (#eq? @reference.class "self"))
  body: (_
    (identifier) @reference.class
    (#eq? @reference.class "self")
    (#not-has-parent? @reference.class dot_index_expression)))

(method
  parameters: (parameters) @name
    (#not-match? @name "\\bself\\b")
  body: (_
    (identifier) @reference.class
    (#eq? @reference.class "self")
    (#not-has-parent? @reference.class dot_index_expression)))

(method body: (_ (super) @reference.class))

(metafield
  value: (metamethod
    parameters: (parameters
      first: (identifier) @reference.class
      (#eq? @reference.class "self"))
    body: (_
      (identifier) @reference.class
      (#eq? @reference.class "self")
      (#not-has-parent? @reference.class dot_index_expression))))

(metafield
  value: (metamethod
    parameters: (parameters
      (identifier) @name
      (#not-match? @name "\\bself\\b"))
    body: (_
      (identifier) @reference.class
      (#eq? @reference.class "self")
      (#not-has-parent? @reference.class dot_index_expression))))
    
(metafield
  value: (metamethod
    body: (_ (super) @reference.class)))

(function_call
  name: [
    (identifier) @name
    (dot_index_expression
      field: (identifier) @name)
  ]) @reference.call
