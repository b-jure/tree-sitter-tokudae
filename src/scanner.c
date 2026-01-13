#include <limits.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <wctype.h>

#include "tree_sitter/alloc.h"
#include "tree_sitter/parser.h"


enum TokenType {
  /* C-style comment */
  TT_CCOMMENT_START = 0,
  TT_CCOMMENT_CONTENT,
  TT_CCOMMENT_END,
  /* multiline raw string */
  TT_STRING_BLOCK_START,
  TT_STRING_BLOCK_CONTENT,
  TT_STRING_BLOCK_END,
  /* sentinel (for error detection) */
  TT_ERROR_SENTINEL,
};


#define tolevel(data)   ((unsigned *)(data))
#define tochar(x)       ((char)(x))
#define uchar(x)        ((unsigned char)(x))

#define advance(lx, s)  ((void)((lx)->advance(lx, s)))
#define next(lx)        advance(lx, false)
#define skip(lx)        advance(lx, true)


static inline bool match (TSLexer *lx, char c) {
  if (lx->lookahead == c) {
    next(lx);
    return true;
  }
  return false;
}


static inline unsigned repeat (TSLexer *lx, char c) {
  unsigned count = 0;
  while (lx->lookahead == c) {
    ++count;
    next(lx);
  }
  return count;
}


void *tree_sitter_tokudae_external_scanner_create () {
  return ts_calloc(1, sizeof(unsigned));
}


void tree_sitter_tokudae_external_scanner_destroy (void *data) {
  ts_free(tolevel(data));
}


unsigned tree_sitter_tokudae_external_scanner_serialize (void *data,
                                                         char *buff) {
  unsigned level = *tolevel(data);
  unsigned nb = 0;
  buff[nb++] = tochar(level & 0xff);
  while (nb < sizeof(level)) {
    level >>= CHAR_BIT;
    buff[nb++] = tochar(level & 0xff);
  }
  return nb;
}


void tree_sitter_tokudae_external_scanner_deserialize (void *data,
                                                       const char *buff,
                                                       unsigned nb) {
  unsigned *plevel = tolevel(data);
  unsigned i = 0;
  if (nb == 0)
    return;
  *plevel |= uchar(buff[i]);
  while (++i < nb)
    *plevel |= (uchar(buff[i]) << (CHAR_BIT * i));
}


static bool blockstart (unsigned *plevel, TSLexer *lx) {
  if (match(lx, '[') && match(lx, '=')) { /* "[=" ? */
    unsigned n = repeat(lx, '='); /* zero or more '=' */
    if (match(lx, '[')) { /* closing "[" ? */
      *plevel = n; /* level 0 is top-level, then 1, etc... */
      lx->result_symbol = TT_STRING_BLOCK_START;
      return true; /* this is start of string block */
    }
  }
  return false; /* not the start of a string block */
}


static bool blockend (unsigned *plevel, TSLexer *lx, bool end) {
  unsigned level = *plevel;
  if (match(lx, ']') && match(lx, '=')) {
    unsigned n = repeat(lx, '=');
    if (level == n && match(lx, ']')) {
      if (end == true) { /* symbol is 'TT_STRING_BLOCK_END' ? */
        *plevel = 0;
        lx->result_symbol = TT_STRING_BLOCK_END;
      } /* otherwise symbol is 'TT_STRING_BLOCK_CONTENT' */
      return true;
    }
  }
  return false;
}


/*
** This macro checks for end of file, and if false it jumps to 'scan' label.
** (Useful 'lx->lookahead' might be '\0' but not end of file.)
*/
#define checkeof(lx)    { if ((lx)->eof(lx) == false) goto scan; }


static bool blockcontent (unsigned *plevel, TSLexer *lx) {
  while (lx->lookahead) {
    if (lx->lookahead == ']') { /* (potential) delimiter? */
      lx->mark_end(lx);
      if (blockend(plevel, lx, false)) { /* valid delimiter? */
        lx->result_symbol = TT_STRING_BLOCK_CONTENT;
        return true;
      } /* invalid delimiter; keep searching for delimiter */
    } else {
    scan:
      next(lx);
    }
  }
  checkeof(lx);
  return false;
}


static bool commentstart (TSLexer *lx) {
  if (match(lx, '/') && match(lx, '*')) {
    lx->mark_end(lx);
    lx->result_symbol = TT_CCOMMENT_START;
    return true;
  }
  return false;
}


#define commentdelimiter(lx)    (match(lx, '*') && match(lx, '/'))


static bool commentcontent (TSLexer *lx) {
  while (lx->lookahead) {
    if (lx->lookahead == '*') { /* (potential) delimiter? */
      lx->mark_end(lx);
      if (commentdelimiter(lx)) { /* valid delimiter? */
        lx->result_symbol = TT_CCOMMENT_CONTENT;
        return true;
      } /* invalid delimiter; keep searching for delimiter */
    } else {
    scan:
      next(lx);
    }
  }
  checkeof(lx);
  return false;
}


static bool commentend (TSLexer *lx) {
  if (commentdelimiter(lx)) {
    lx->mark_end(lx);
    lx->result_symbol = TT_CCOMMENT_END;
    return true;
  }
  return false;
}


bool tree_sitter_tokudae_external_scanner_scan (void *data, TSLexer *lx,
                                                const bool *sym) {
  unsigned *plevel = tolevel(data);
  bool res;
  if (sym[TT_ERROR_SENTINEL])
    res = false;
  else if (sym[TT_STRING_BLOCK_END])
    res = blockend(plevel, lx, true);
  else if (sym[TT_STRING_BLOCK_CONTENT])
    res = blockcontent(plevel, lx);
  else if (sym[TT_CCOMMENT_CONTENT])
    res = commentcontent(lx);
  else if (sym[TT_CCOMMENT_END])
    res = commentend(lx);
  else { /* else it might be start of a block string/comment */
    while (iswspace(lx->lookahead))
      skip(lx); /* whitespace is not part of a string/comment */
    if (sym[TT_STRING_BLOCK_START])
      res = blockstart(plevel, lx);
    else if (sym[TT_CCOMMENT_START])
      res = commentstart(lx);
    else /* otherwise no symbols matched */
      res = false;
  }
  return res;
}
