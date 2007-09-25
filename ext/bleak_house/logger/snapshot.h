#include "ruby.h"
#include "env.h"
#include "node.h"
#include "st.h"
#include "re.h"

typedef struct RVALUE {
    union {
        struct {
            unsigned long flags; /* always 0 for freed obj */
            struct RVALUE *next;
        } free;
        struct RBasic  basic;
        struct RObject object;
        struct RClass  klass;
        struct RFloat  flonum;
        struct RString string;
        struct RArray  array;
        struct RRegexp regexp;
        struct RHash   hash;
        struct RData   data;
        struct RStruct rstruct;
        struct RBignum bignum;
        struct RFile   file;
        struct RNode   node;
        struct RMatch  match;
        struct RVarmap varmap;
        struct SCOPE   scope;
    } as;
} RVALUE;

struct heaps_slot {
    void *membase;
    RVALUE *slot;
    int limit;
};

static st_table *sym_tbl;
static st_table *sym_rev_tbl;

struct heaps_slot * rb_gc_heap_slots();
int rb_gc_heaps_used();
int rb_gc_heaps_length();
