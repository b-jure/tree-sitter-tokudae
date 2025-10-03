/**
 * @file Parser for the Tokudae programming language
 * @author Jure Bagić <jurebagic99@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check


const list_seq = (rule, separator, trailing_separator = false) =>
  trailing_separator
    ? seq(rule, repeat(seq(separator, rule)), optional(separator))
    : seq(rule, repeat(seq(separator, rule)));

const name_list = ($) => list_seq(field('name', $.identifier), ',');

const toparams = ($, rule) => alias(rule, $.parameters);

const parameters = function($, parenthesized = true, method = false) {
  const rule = method ? $._method_parameter_list : $._parameter_list;
  return field('parameters', toparams($, parenthesized
                             ? seq('(', optional(rule), ')')
                             : seq('|', optional(rule), '|')));
}

module.exports = grammar({
  name: 'tokudae',

  extras: $ => [/\s/, $.comment],

  conflicts: $ => [[$._parameter_list]],

  externals: $ => [
    /* C-style comment */
    $.c_comment_start,
    $.c_comment_content,
    $.c_comment_end,
    /* multiline raw string */
    $.string_block_start,
    $.string_block_content,
    $.string_block_end,
    /* sentinel (for error detection) */
    $.error_sentinel
  ],

  supertypes: $ => [$.declaration, $.statement, $.expression, $.variable],

  rules: {
    chunk: $ => prec(1,
      seq(
        repeat(choice($.declaration, $.statement)),
        optional($.return_statement)
      )
    ),

    declaration: $ => choice(
      field(
        'local_declaration',
        alias($._local_variable_declaration, $.variable_declaration)
      ),
      field(
        'local_declaration',
        alias($._local_function_declaration, $.function_declaration)
      ),
      field(
        'local_declaration',
        alias($._local_class_declaration, $.class_declaration)
      ),
    ),

    _local_variable_declaration: $ => seq($._variable_declaration, ';'),

    _variable_declaration: $ => seq(
      'local',
      choice(
        alias($._att_name_list, $.variable_list),
        alias($._local_variable_assignment, $.assignment)
      )
    ),

    _local_variable_assignment: $ => seq(
      alias($._att_name_list, $.variable_list),
      '=',
      alias($._variable_assignment_explist, $.expression_list)
    ),

    _att_name_list: ($) => list_seq(
      seq(
        field('name', $.identifier),
        optional(field('attribute', alias($._attrib, $.attribute)))
      ),
      ','
    ),

    _attrib: $ => seq('<', $.identifier, '>'),

    _local_function_declaration: $ => seq(
      'local',
      'fn',
      field('name', $.identifier),
      parameters($),
      $._function_body
    ),

    _local_class_declaration: $ => prec.right(seq(
      'local',
      'class',
      field('name', $.identifier),
      optional($._inherit),
      optional(field('body', $.class_body))
    )),

    statement: $ => choice(
      $.empty_statement,
      $.assignment_statement,
      $.call_statement,
      $.break_statement,
      $.continue_statement,
      $.function_statement,
      $.class_statement,
      $.loop_statement,
      $.while_statement,
      $.do_while_statement,
      $.for_statement,
      $.foreach_statement,
      $.if_statement,
      $.switch_statement,
      $.block_statement,
      $.return_statement
    ),

    empty_statement: _ => ';',

    assignment_statement: $ => seq($.assignment, ';'),

    assignment: $ => choice(
      seq(
        alias($._variable_assignment_varlist, $.variable_list),
        choice('=', $.compound_assignment),
        alias($._variable_assignment_explist, $.expression_list)
      ),
      $.increment,
      $.decrement
    ),

    compound_assignment: _ => choice(
      '+=', '-=', '*=', '/=', '//=', '**=', '%=',
      '&=', '|=', '^=', '>>=', '<<=', '..='
    ),

    _variable_assignment_varlist: $ => list_seq(
      field('name', $.variable), ','
    ),

    _variable_assignment_explist: $ => list_seq(
      field('value', $.expression), ','
    ),

    increment: $ => seq(field('name', $.variable), '++'),

    decrement: $ => seq(field('name', $.variable), '--'),

    call_statement: $ => seq(
      alias($._final_expression_call, $.function_call), ';'
    ),

    break_statement: _ => seq('break', ';'),

    continue_statement: _ => seq('continue', ';'),

    function_statement: $ => seq(
      'fn',
      field('name', $._statement_name),
      parameters($),
      $._function_body
    ),

    class_statement: $ => prec.right(seq(
      'class',
      field('name', $._statement_name),
      optional($._inherit),
      optional(field('body', $.class_body))
    )),

    _statement_name: $ => choice(
      $.identifier,
      alias($._statement_name_prefix, $.dot_index_expression)
    ),

    _statement_name_prefix: $ => seq(
      field('object', $._statement_name),
      '.',
      field('field', $.identifier)
    ),

    loop_statement: $ => seq('loop', field('body', $.statement)),

    while_statement: $ => seq(
      'while',
      field('condition', $.expression),
      field('body', $.statement)
    ),

    do_while_statement: $ => seq(
      'do',
      field('body', $.statement),
      'while',
      field('condition', $.expression),
      ';'
    ),

    _for_clause: $ => choice(
      seq('(', $.for_clause, ')'),
      seq($.for_clause, ';')
    ),

    for_clause: $ => seq(
      optional(field('init', $._for_init)),
      ';',
      optional(field('condition', $.expression)),
      ';',
      optional(field('next', $.assignment))
    ),

    _for_init: $ => choice(
      alias($._variable_declaration, $.variable_declaration),
      $.assignment
    ),

    for_statement: $ => seq(
      'for',
      field('clause', $._for_clause),
      field('body', $.statement)
    ),

    foreach_statement: $ => seq(
      'foreach',
      alias($._name_list, $.variable_list),
      'in',
      alias($._foreach_explist, $.expression_list),
      field('body', $.statement)
    ),

    _foreach_explist: $ => choice(
      seq(
        field('iterator', $.expression),
        optional(seq(
          ',',
          field('invariant_state', $.expression),
          optional(
            seq(
              ',',
              field('control_var', $.expression),
              optional(seq(',', field('tbc_var', $.expression)))
            )
          )
        ))
      )
    ),

    if_statement: $ => prec.right(seq(
      'if',
      field('condition', $.expression),
      field('consequence', $.statement),
      optional(field('alternative', $.else_statement))
    )),

    else_statement: $ => seq('else', field('body', $.statement)),

    switch_statement: $ => seq(
      'switch',
      field('condition', $.expression),
      '{',
      optional(field('body', $.switch_body)),
      '}'
    ),

    switch_body: $ => choice(
      seq(
        repeat1(field('case', $.switch_case)),
        optional(field('default', $.default_case))
      ),
      seq(
        repeat(field('case', $.switch_case)),
        field('default', $.default_case)
      )
    ),

    switch_case: $ => seq(
      'case',
      field('value', $.expression),
      ':',
      optional(field('body', $.case_body))
    ),

    default_case: $ => seq(
      'default',
      ':',
      optional(field('body', $.case_body))
    ),

    case_body: $ => repeat1($.statement),

    return_statement: $ => prec.right(seq(
      'return',
      optional(alias($._expression_list, $.expression_list)),
      optional(';')
    )),

    _expression_list: $ => prec.right(seq(
      $.expression, repeat(seq(',', $.expression))
    )),

    expression: $ => choice(
      $.nil,
      $.true,
      $.false,
      $.char,
      $.number,
      $.string,
      $.vararg_expression,
      $.function_definition,
      $.variable,
      $.function_call,
      $.parenthesized_expression,
      $.list_constructor,
      $.table_constructor,
      $.class_definition,
      $.binary_expression,
      $.unary_expression
    ),

    nil: _ => 'nil',

    true: _ => 'true',

    false: _ => 'false',

    char: $ => seq(
      field('start', '\''),
      field(
        'content',
        choice(
          $.escape_sequence,
          alias(token.immediate(/[^\n']/), $.character),
        )
      ),
      field('end', '\''),
    ),

    number: _ => {
      const bdig = /[01]/;
      const binliteral = seq(
        choice('0b', '0B'),
        bdig,
        repeat(choice(bdig, '_'))
      );

      const odig = /[0-7]/;
      const octliteral = seq(odig, repeat(choice(odig, '_')));

      const ddig = /[0-9]/;
      function exponent(e) {
        return seq(
          choice(e.toLowerCase(), e.toUpperCase()),
          optional(choice('+', '-')),
          ddig,
          repeat(choice(ddig, '_'))
        );
      }
      const decliteral = choice(
        seq(
          '.',
          repeat1(ddig),
          optional(exponent('e'))
        ),
        seq(
          seq(ddig, repeat(choice(ddig, '_'))),
          optional(
            choice(
              exponent('e'),
              seq('.', repeat(ddig), optional(exponent('e')))
            )
          )
        )
      );

      const hdig = /[0-9a-fA-F]/;
      const hexliteral = seq(
        choice('0x', '0X'),
        choice(
          seq(
            '.',
            repeat1(hdig),
            optional(exponent('p'))
          ),
          seq(
            hdig,
            repeat(choice(hdig, '_')),
            optional(seq('.', repeat(hdig))),
            optional(exponent('p'))
          )
        )
      );

      return token(choice(
        'inf',
        'infinity',
        binliteral,
        octliteral,
        decliteral,
        hexliteral
      ));
    },

    string: $ => choice($._doublequote_string, $._block_string),

    _doublequote_string: $ => seq(
      field('start', alias('"', '"')),
      field(
        'content',
        optional(alias($.doublequote_string_content, $.string_content)),
      ),
      field('end', alias('"', '"'))
    ),

    doublequote_string_content: $ => repeat1(
      choice(token.immediate(prec(1, /[^"\\]+/)), $.escape_sequence)
    ),

    escape_sequence: _ => token.immediate(
      seq(
        '\\',
        choice(
          /[\neabfnrtv\\'"]/,
          /[0-9]{1,3}/,
          /x[0-9a-fA-F]{2}/,
          /u\{[0-9a-fA-F]+\}/,
          /u\[[0-9a-fA-F]+\]/
        )
      )
    ),
    
    _block_string: $ => seq(
      field('start', alias($.string_block_start, '[=[')),
      field('content', alias($.string_block_content, $.string_content)),
      field('end', alias($.string_block_end, ']=]'))
    ),

    vararg_expression: _ => '...',

    function_definition: $ => seq(
      choice($._function_clause, $._lambda_clause),
      $._function_body
    ),

    _function_clause: $ => seq('fn', parameters($)),

    _lambda_clause: $ => parameters($, false),

    _prefix_expression: $ => prec(1, choice(
      $.variable,
      $.function_call,
      $.parenthesized_expression,
      $.super
    )),

    variable: $ => choice(
      $.identifier,
      $.bracket_index_expression,
      $.dot_index_expression
    ),

    bracket_index_expression: $ => seq(
      field('object', $._prefix_expression),
      '[',
      field('field', $.expression),
      ']'
    ),

    dot_index_expression: $ => seq(
      field('object', $._prefix_expression),
      '.',
      field('field', $.identifier)
    ),

    function_call: $ => seq($._final_expression_call, optional('?')),

    _final_expression_call: $ => seq(
      field('name', $._prefix_expression),
      field('arguments', $.arguments),
    ),

    arguments: $ => seq('(', optional(list_seq($.expression, ',')), ')'),

    parenthesized_expression: $ => seq('(', $.expression, ')'),

    super: _ => 'super',

    list_constructor: $ => seq('[', optional($._list_elements), ']'),

    _list_elements: $ => list_seq($.element, $._separator, true),

    element: $ => field('value', $.expression),

    table_constructor: $ => seq('{', optional($._table_fields), '}'),

    _table_fields: $ => list_seq($.field, $._separator, true),

    field: $ => choice(
      seq(
        '[',
        field('name', $.expression),
        ']',
        '=',
        field('value', $.expression)
      ),
      seq(field('name', $.identifier), '=', field('value', $.expression))
    ),
    
    _separator: $ => choice(',', ';'),

    _name_list: $ => name_list($),

    block_statement: $ => seq('{', optional(alias($._block, $.block)), '}'),

    _block: $ => prec(1, choice(
      seq(
        repeat1(choice($.declaration, $.statement)),
        optional($.return_statement)
      ),
      seq(
        repeat(choice($.declaration, $.statement)),
        $.return_statement
      ),
    )),

    class_definition: $ => prec.right(seq(
      'class',
      optional($._inherit),
      optional($.class_body)
    )),

    _inherit: $ => seq('inherits', field('superclass', $.expression)),

    class_body: $ => seq('{', repeat($._class_entry), '}'),

    _class_entry: $ => choice(
      $._class_value,
      field(
        'local_declaration',
        alias($._local_variable_declaration, $.variable_declaration)
      )
    ),

    _class_value: $ => choice(
      field('method', $.method),
      field('metafield', $.metafield)
    ),

    method: $ => seq(
      'fn',
      field('name', $.identifier),
      parameters($, true, true),
      $._function_body
    ),

    metafield: $ => seq(
      field('field', $.identifier),
      '=',
      field('value', choice($.metamethod, $.expression)),
      ';'
    ),

    metamethod: $ => prec(1, seq(
      field('parameters',
        choice(
          seq('|', optional(toparams($, $._method_parameter_list)), '|'),
          seq("fn", '(', optional(toparams($, $._method_parameter_list)), ')')
        )
      ),
      $._function_body
    )),

    _method_parameter_list: $ => prec(1, choice(
      seq(
        field('first', $.identifier),
        field('rest', optional(seq(',', $._parameter_list)))
      ),
      $.vararg_expression
    )),

    _parameter_list: $ => choice(
      seq(name_list($), optional(seq(',', $.vararg_expression))),
      $.vararg_expression
    ),

    _function_body: $ => prec(1, seq(
      optional('::'),
      field('body', choice($.block_statement, $.statement))
    )),

    identifier: _ => token(/[a-zA-Z_][a-zA-Z0-9_]*/),

    binary_expression: $ => choice(
      ...[
        ['or', 1],
        ['and', 2],
        ['|', 3],
        ['^', 4],
        ['&', 5],
        ['==', 6], ['!=', 6],
        ['<', 7], ['<=', 7], ['>', 7], ['>=', 7],
        ['<<', 8], ['>>', 8],
        ['+', 10], ['-', 10],
        ['*', 11], ['/', 11], ['//', 11], ['%', 11],
      ].map(([operator, precedence]) => prec.left(
        precedence,
        seq(
          field('left', $.expression),
          field('operator', operator),
          field('right', $.expression)
        )
      )),
      ...[
        ['..', 9],
        ['**', 13],
      ].map(([operator, precedence]) => prec.right(
        precedence,
        seq(
          field('left', $.expression),
          field('operator', operator),
          field('right', $.expression)
        )
      ))
    ),

    unary_expression: $ => prec.left(
      12,
      seq(
        field('operator', choice('!', '-', '~')),
        field('operand', $.expression),
      )
    ),

    comment: $ => choice(
      seq(
        field('start', '#'),
        field('content', alias(/[^\r\n]*/, $.comment_content))
      ),
      seq(
        field('start', '///'),
        field('content', alias(/[^\r\n]*/, $.comment_content))
      ),
      seq(
        field('start', alias($.c_comment_start, '/*')),
        field('content', alias($.c_comment_content, $.comment_content)),
        field('end', alias($.c_comment_end, '*/'))
      )
    ),
  }
});
