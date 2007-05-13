
require 'rubygems'
require 'inline'

class BleakHouse
  class CLogger

    MAX_UNIQ_TAGS = 1536 # per frame
    MAX_TAG_LENGTH = 192 # tag plus fully namespaced classname

    def mem_usage
      a = `ps -o vsz,rss -p #{Process.pid}`.split(/\s+/)[-2..-1].map{|el| el.to_i}
      [a.first - a.last, a.last]
    end

    inline do |builder|
      builder.include '"node.h"' # struct RNode
      builder.include '"st.h"'  # struct st_table
      builder.include '"re.h"'  # struct RRegexp
      builder.include '"env.h"' # various structs

      builder.prefix <<-EOC
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

        struct heaps_slot * rb_gc_heap_slots();
        int rb_gc_heaps_used();
        int rb_gc_heaps_length();
      EOC

      # number of struct heaps_slots used
      builder.c <<-EOC
        static int
        heaps_used() {
          return rb_gc_heaps_used();
        }
      EOC

      # length of the struct heaps_slots allocated
      builder.c <<-EOC
        static int
        heaps_length() {
          return rb_gc_heaps_length();
        }
      EOC

      OBJ_TYPES = ["T_NIL",
                  "T_OBJECT",
                  "T_CLASS",
                  "T_ICLASS",
                  "T_MODULE",
                  "T_FLOAT",
                  "T_STRING",
                  "T_REGEXP",
                  "T_ARRAY",
                  "T_FIXNUM",
                  "T_HASH",
                  "T_STRUCT",
                  "T_BIGNUM",
                  "T_FILE",
                  "T_TRUE",
                  "T_FALSE",
                  "T_DATA",
                  "T_SYMBOL",
                  "T_MATCH"]

      RAW_TYPES = ["T_NONE",
                  "T_BLKTAG",
                  "T_UNDEF",
                  "T_VARMAP",
                  "T_SCOPE",
                  "T_NODE"]

      # writes a frame to a file
      builder.c <<-EOC
        static void
        VALUE snapshot(VALUE logfile, VALUE tag, VALUE _specials) {
          Check_Type(logfile, T_STRING);
          Check_Type(tag, T_STRING);

          RVALUE *p, *pend;
          struct heaps_slot * heaps = rb_gc_heap_slots();

          int specials = RTEST(_specials);

          FILE *obj_log = fopen(StringValueCStr(logfile), "r");
          int is_new;
          if (!(is_new = (obj_log == NULL)))
            fclose(obj_log);

          if ((obj_log = fopen(StringValueCStr(logfile), "a+")) == NULL)
            rb_raise(rb_eRuntimeError, "couldn't open snapshot file");

          if (is_new) 
            fprintf(obj_log, \"---\\n");
          fprintf(obj_log, \"- - %i\\n", time(0));
          VALUE mem = rb_funcall(self, rb_intern("mem_usage"), 0);
          fprintf(obj_log, \"  - :\\"memory usage/swap\\": %i\\n", NUM2INT(RARRAY_PTR(mem)[0]));
          fprintf(obj_log, \"    :\\"memory usage/real\\": %i\\n", NUM2INT(RARRAY_PTR(mem)[1]));
          
          /* haha */
          char tags[#{MAX_UNIQ_TAGS}][#{MAX_TAG_LENGTH}];
          char current_tag[2048];
          int counts[#{MAX_UNIQ_TAGS}];
          int current_pos = 0;
          
          int filled_slots = 0;
          int free_slots = 0;

          int i, j;
          for (i = 0; i < rb_gc_heaps_used(); i++) {
            p = heaps[i].slot;
            pend = p + heaps[i].limit;
            for (; p < pend; p++) {
              if (p->as.basic.flags) { /* always 0 for freed objects */
                filled_slots ++;
                sprintf(current_tag, "");
                switch (TYPE(p)) {
                  #{RAW_TYPES.map do |type|
                      "case #{type}:
                          if (specials)
                            sprintf(current_tag , \"%s::::_#{type[2..-1].downcase}\", StringValueCStr(tag));
                          break;
                      "
                    end.flatten.join}
                  default:
                    if (!p->as.basic.klass) {
                      sprintf(current_tag , "%s::::_unknown", StringValueCStr(tag));
                    } else {
                      sprintf(current_tag , "%s::::%s", StringValueCStr(tag), rb_obj_classname((VALUE)p));
                    }
                }
                if (strlen(current_tag) > #{MAX_TAG_LENGTH})
                  rb_raise(rb_eRuntimeError, "tag + classname too big; increase MAX_TAG_LENGTH (#{MAX_TAG_LENGTH})");
                if (strcmp(current_tag, "")) {
                  for (j = 0; j < current_pos; j++) {
                    if (!strcmp(tags[j], current_tag)) {
                      counts[j] ++;
                      break;
                    }
                  }
                  if (j == current_pos) {
                    /* found a new one */
                    if (current_pos == #{MAX_UNIQ_TAGS})
                      rb_raise(rb_eRuntimeError, "exhausted tag array; increase MAX_UNIQ_TAGS (#{MAX_UNIQ_TAGS})");
                    sprintf(tags[current_pos], current_tag);
                    counts[current_pos] = 1;
                    current_pos ++;
                  }
                }
              } else {
                free_slots ++;
              }
            }
          }
          fprintf(obj_log, \"    :\\"heap usage/filled slots\\": %i\\n", filled_slots);
          fprintf(obj_log, \"    :\\"heap usage/free slots\\": %i\\n", free_slots);
          for (j = 0; j < current_pos; j++) {
            fprintf(obj_log, "    :\\"%s\\": %i\\n", tags[j], counts[j]);
          }
          fclose(obj_log);
          
          /* request GC run */          
          rb_funcall(rb_mGC, rb_intern("start"), 0); 
          /* to get a custom module: rb_const_get(parentModule, "ModuleName") 
              parent module can be something like rb_mKernel for the toplevel */
          return Qtrue;
        }
      EOC
    end

  end
end
