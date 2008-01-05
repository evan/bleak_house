#include "ruby.h"
#include "env.h"
#include "node.h"
#include "st.h"
#include "re.h"
#include "util.h"
#include "intern.h"
#include "string.h"

/* Histogram of most common Rails classes */
static char * builtins[] = {
 "String",
 "Array",
 "Hash",
 "Class",
 "Regexp",
 "Proc",
 "ActionController::Routing::DividerSegment",
 "Gem::Version",
 "Gem::Version::Requirement",
 "Bignum",
 "Symbol",
 "Time",
 "MatchData",
 "Gem::Specification",
 "ActionController::Routing::StaticSegment",
 "Gem::Dependency",
 "Module",
 "ActionController::Routing::DynamicSegment",
 "Range",
 "ActionController::Routing::Route",
 "Float",
 "HashWithIndifferentAccess",
 "Method",
 "Enumerable",
 "Comparable",
 "Set",
 "File",
 "Object",
 "NameError",
 "Thread",
  "_node",
  "_none",
  "_blktag",
  "_undef",
  "_varmap",
  "_scope",
  "_unknown" 
};

#define BUILTINS_SIZE 30
#define SPECIALS_SIZE 7

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

typedef struct st_table_entry st_table_entry;

struct st_table_entry {
    unsigned int hash;
    st_data_t key;
    st_data_t record;
    st_table_entry *next;
};

struct st_table * rb_parse_sym_tbl();
struct heaps_slot * rb_gc_heap_slots();
int rb_gc_heaps_used();
int rb_gc_heaps_length();

char * inspect(VALUE);
char * handle_exception(VALUE);
int lookup_builtin(char *);
