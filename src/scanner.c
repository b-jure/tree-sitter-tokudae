#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <limits.h>
#include <assert.h>
#include <wctype.h>

#include "tree_sitter/alloc.h"
#include "tree_sitter/parser.h"


enum TokenType {
    /* C-style comment */
    TT_CCOMMENT_START,
    TT_CCOMMENT_CONTENT,
    TT_CCOMMENT_END,
    /* multiline raw string */
    TT_STRING_BLOCK_START,
    TT_STRING_BLOCK_CONTENT,
    TT_STRING_BLOCK_END,
    /* sentinel (for error detection) */
    TT_ERROR_SENTINEL,
};


typedef struct SData {
    uint64_t level; /* number of '=' - 1 in string block opening delimiter */
    char _mark; /* (for calculating offset) */
} SData;

/*
** Size of 'level' member in SData (in bytes).
** (This way when 'level' type is changed it does not break
** (de)serialization, however adding new members after 'level' will.)
*/
#define LEVELBYTES      (offsetof(SData, _mark) - offsetof(SData, level))


#define tosd(data)      ((SData *)(data))
#define tochar(x)       ((char)(x))
#define tosizet(x)      ((size_t)(x))


#define advance(lx,s)   ((void)((lx)->advance(lx, s)))
#define next(lx)        advance(lx, false)
#define skip(lx)        advance(lx, true)


#define resetstate(sd)      memset(sd, 0, sizeof(*(sd)))


static inline bool match(TSLexer *lx, char c) {
    if (lx->lookahead == c) {
        next(lx);
        return true;
    }
    return false;
}


static inline size_t repeat(TSLexer *lx, char c) {
    size_t count = 0;
    while (lx->lookahead == c) {
        ++count;
        next(lx);
    }
    return count;
}


void *tree_sitter_tokudae_external_scanner_create() {
    return ts_calloc(1, sizeof(SData));
}


void tree_sitter_tokudae_external_scanner_destroy(void *data) {
    ts_free(tosd(data));
}


unsigned tree_sitter_tokudae_external_scanner_serialize(void *data,
                                                        char *buff) {
    SData *sd = tosd(data);
    size_t level = sd->level;
    unsigned nb = 0;
    buff[nb++] = tochar(level & 0xff);
    while (nb < LEVELBYTES) {
        level >>= CHAR_BIT;
        buff[nb++] = tochar(level & 0xff);
    }
    return nb;
}


void tree_sitter_tokudae_external_scanner_deserialize(void *data,
                                                      const char *buff,
                                                      unsigned nb) {
    SData *sd = tosd(data);
    unsigned i = 0;
    if (nb == 0) return;
    assert(nb == LEVELBYTES);
    sd->level |= tosizet(buff[i]);
    while (++i < nb)
        sd->level |= (tosizet(buff[i]) << (CHAR_BIT * i));
}


static bool blockstart(SData *sd, TSLexer *lx) {
    if (match(lx, '[') && match(lx, '=')) { /* "[=" ? */
        size_t level = repeat(lx, '='); /* zero or more '=' */
        if (match(lx, '[')) { /* closing "[" ? */
            sd->level = level; /* level 0 is top-level, then 1, etc... */
            lx->result_symbol = TT_STRING_BLOCK_START;
            return true; /* this is start of string block */
        }
    }
    return false; /* not the start of a string block */
}


static bool blockend(SData *sd, TSLexer *lx, bool end) {
    if (match(lx, ']') && match(lx, '=')) {
        size_t level = repeat(lx, '=');
        if (sd->level == level && match(lx, ']')) {
            if (end == true) { /* symbol is 'TT_STRING_BLOCK_END' ? */
                resetstate(sd);
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


static bool blockcontent(SData *sd, TSLexer *lx) {
    while (lx->lookahead) {
        if (lx->lookahead == ']') { /* (potential) delimiter? */
            lx->mark_end(lx);
            if (blockend(sd, lx, false)) { /* valid delimiter? */
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


static bool commentstart(TSLexer *lx) {
    if (match(lx, '/') && match(lx, '*')) {
        lx->mark_end(lx);
        lx->result_symbol = TT_CCOMMENT_START;
        return true;
    }
    return false;
}


#define commentdelimiter(lx)    (match(lx, '*') && match(lx, '/'))


static bool commentcontent(TSLexer *lx) {
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


static bool commentend(TSLexer *lx) {
    if (commentdelimiter(lx)) {
        lx->mark_end(lx);
        lx->result_symbol = TT_CCOMMENT_END;
        return true;
    }
    return false;
}


static inline void skipws(TSLexer *lx) {
    while (iswspace(lx->lookahead))
        skip(lx);
}


bool tree_sitter_tokudae_external_scanner_scan(void *data, TSLexer *lx,
                                               const bool *sym) {
    SData *sd = tosd(data);
    bool res;
    if (sym[TT_ERROR_SENTINEL])
        res = false;
    else if (sym[TT_STRING_BLOCK_END])
        res = blockend(sd, lx, true);
    else if (sym[TT_STRING_BLOCK_CONTENT])
        res = blockcontent(sd, lx);
    else if (sym[TT_CCOMMENT_CONTENT])
        res = commentcontent(lx);
    else if (sym[TT_CCOMMENT_END])
        res = commentend(lx);
    else { /* otherwise might be start of block string or comment */
        skipws(lx); /* whitespace is not part of string or comment */
        if (sym[TT_STRING_BLOCK_START])
            res = blockstart(sd, lx);
        else if (sym[TT_CCOMMENT_START])
            res = commentstart(lx);
        else /* otherwise no symbols matched */
            res = false;
    }
    return res;
}
