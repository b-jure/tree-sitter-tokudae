/**
 * @file Parser for the Tokudae programming language
 * @author Jure Bagić <jurebagic99@gmail.com>
 * @license MIT
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

module.exports = grammar({
  name: 'tokudae',

  extras: $ => [
    /\s/,
    $.comment
    $.longcomment
  ],

  rules: {
    chunk: $ => $.block,

    assignop: $ => choice(
      '=', '+=', '-=', '*=', '/=', '//=', '**=',
      '%=', '&=', '|=', '^=', '>>=', '<<=', '..='
    ),

    expstm: $ => choice(
      seq($.varlist, $.assignop, $.explist),
      seq($.var, '++'),
      seq($.var, '--')
    ),

    varlist: $ => seq($.var, repeat(seq(',', $.var))),

    var: $ => choice(
      $.Name,
      seq($.prefixexp, '[', $.exp, ']'),
      seq($.prefixexp, '.', $.Name)
    ),

    breakstm: $ => seq('break', ';'),

    continuestm: $ => seq('continue', ';'),

    fnstm: $ => seq('fn', $.dottedname, $.parenparams, $.funcbody),

    classstm: $ => seq('class', $.dottedname, optional($.inherit), optional($.classbodystm)),

    dottedname: $ => seq($.Name, repeat(seq('.', $.Name))),

    loopstm: $ => seq('loop', $.stm),

    whilestm: $ => seq('while', $.exp, $.stm),

    dowhilestm: $ => seq('do', $.stm, 'while', $.exp, ';'),

    forinit: $ => choice($.localstm, $.expstm),

    forinfix: $ => seq(
      optional($.forinit), ';',
      optional($.exp), ';',
      optional($.expstm)
    ),

    forclauses: $ => choice(
      seq('(', $.forinfix, ')'),
      seq($.forinfix, ';')
    ),

    forstm: $ => seq('for', $.forclauses, $.stm),

    forexplist: $ => choice(
      seq($.exp, optional(seq(',', $.exp))),
      seq($.exp, ',', $.exp, optional(seq(',', $.exp))),
      seq($.exp, ',', $.exp, ',', $.exp, optional(seq(',', $.exp)))
    ),

    foreachstm: $ => seq('foreach', $.namelist, 'in', $.forexplist, $.stm),

    ifstm: $ => seq('if', $.exp, $.stm, optional(seq('else', $.stm))),

    switchbody: $ => seq(
      '{',
      repeat(seq('case', $.exp, ':', repeat($.stm))),
      optional(seq('default', ':', repeat($.stm))),
      '}'
    ),

    switchstm: $ => seq('switch', $.exp, $.switchbody),

    blockstm: $ => seq('{', $.loopblock, '}'),

    loopblock: $ => choice(repeat($.decl), $.switchblock),

    switchblock: $ => choice(repeat($.decl), $.block),

    returnstm: $ => seq('return', optional($.explist), optional(';')),

    functiondef: $ => choice(
      seq('fn', $.parenparams, $.funcbody),
      seq($.pipeparams, $.funcbody)
    ),

    listdef: $ => seq('[', optional($.elementlist), ']'),

    elementlist: $ => seq($.exp, repeat(seq($.sep, $.exp)), optional($.sep)),

    tabledef: $ => seq('{', optional($.fieldlist), '}'),

    fieldlist: $ => seq($.field, repeat(seq($.sep, $.field)), optional($.sep)),

    field: $ => choice(
      seq('[', $.exp, ']', '=', $.exp),
      seq($.Name, '=', $.exp)
    ),

    sep: $ => choice(',', ';'),

    pipeparams: $ => seq('|', optional($.parameters), '|'),

    method: $ => seq('fn', $.Name, $.parenparams, $.funcbody),

    localfn: $ => seq('local', 'fn', $.Name, $.parenparams, $.funcbody),

    parenparams: $ => seq('(', optional($.parameters), ')'),

    parameters: $ => choice(
      seq($.namelist, optional(seq(',', '...'))),
      '...'
    ),

    namelist: $ => seq($.Name, repeat(seq(',', $.Name))),

    funcbody: $ => seq(optional('::'), $.funcblock),

    funcblock: $ => choice(
      seq('{', $.block, '}'),
      $.stm
    ),

    block: $ => seq(repeat($.decl), optional($.returnstm)),

    decl: $ => choice(
      seq($.localstm, ';'),
      $.localfn,
      $.localclass,
      $.stm
    ),

    localstm: $ => seq('local', $.attnamelist, optional(seq('=', $.explist))),

    attnamelist: $ => seq($.Name, optional($.attrib), repeat(seq(',', $.Name, optional($.attrib)))),

    attrib: $ => seq('<', $.Name, '>'),

    localclass: $ => seq('local', 'class', $.Name, optional($.inherit), optional($.classbodystm)),

    stm: $ => choice(
      ';',
      seq($.expstm, ';'),
      seq($.call, ';'),
      $.breakstm,
      $.continuestm,
      $.fnstm,
      $.classstm,
      $.loopstm,
      $.whilestm,
      $.dowhilestm,
      $.forstm,
      $.foreachstm,
      $.ifstm,
      $.switchstm,
      $.blockstm,
      $.returnstm
    ),

    classdef: $ => seq('class', optional($.inherit), optional($.classbodystm)),

    inherit: $ => seq('inherits', $.exp),

    classbodystm: $ => seq('{', repeat($.classvaluestm), '}'),

    classvaluestm: $ => choice($.classvalue, seq($.localstm, ';')),

    classvalue: $ => choice($.method, $.metafield),

    metafield: $ => seq($.Name, '=', $.exp, ';'),

    prefixexp: $ => choice(
      $.var,
      seq($.call, optional('?')),
      seq('(', $.exp, ')'),
      'super'
    ),

    call: $ => seq($.prefixexp, '(', optional($.explist), ')'),

    explist: $ => seq($.exp, repeat(seq(',', $.exp))),

    exp: $ => choice(
      'true', 'false', 'nil', '...', 'inf', 'infinity',
      $.DecInt, $.OctInt, $.HexInt, $.BinInt,
      $.DecFlt, $.HexFlt,
      $.String, $.LongString,
      $.listdef, $.tabledef,
      $.functiondef, $.classdef,
      $.prefixexp,
      prec.left(1, seq($.exp, 'or', $.exp)),
      prec.left(2, seq($.exp, 'and', $.exp)),
      prec.left(3, seq($.exp, '|', $.exp)),
      prec.left(4, seq($.exp, '^', $.exp)),
      prec.left(5, seq($.exp, '&', $.exp)),
      prec.left(6, seq($.exp, choice('==', '!='), $.exp)),
      prec.left(7, seq($.exp, choice('<', '<=', '>', '>='), $.exp)),
      prec.left(8, seq($.exp, choice('<<', '>>'), $.exp)),
      prec.right(9, seq($.exp, '..', $.exp)),
      prec.left(10, seq($.exp, choice('+', '-'), $.exp)),
      prec.left(11, seq($.exp, choice('*', '/', '//', '%'), $.exp)),
      prec(12, seq(choice('-', '~', '!'), $.exp)), // (unary)
      prec.right(13, seq($.exp, '**', $.exp))
    ),

    Name: _ => /[a-zA-Z_][a-zA-Z0-9_]*/,

    DecInt: _ => token(/\b\d[0-9_]*\b/),
    OctInt: _ => token(/\b[0-7][0-7_]*\b/),
    HexInt: _ => token(/\b0[xX][0-9a-fA-F][0-9a-fA-F_]*\b/),
    BinInt: _ => token(/\b0[bB][01][01_]*\b/),

    DecFlt: _ => token(/\b(\d[0-9_]*(?:\.\d*(?:[eE][-+]?\d[0-9_]*)?)|(?:[eE][-+]?\d[0-9_]*))|(\.\d+(?:[eE][-+]?\d[0-9_]*)?)\b/),
    HexFlt: _ => token(/\b0[xX](?:(?:[0-9a-fA-F][0-9a-fA-F_]*)?\.[0-9a-fA-F]+[pP][-+]?\d[0-9_]*)|(?:[0-9a-fA-F][0-9a-fA-F_]*\.?[pP][-+]?\d[0-9_]*)\b/),

    String: _ => token(/"(?:[^"\\]\|\\.)*"/),
    LongString: _ => token(/\[(=+)\[[\s\S]*?\]\1\]/),

    comment: _ => token(seq(choice('#', '///'), /.*/)),
    longcomment: _ => token(/\/\*[\s\S]*?\*\//),
  }
});
