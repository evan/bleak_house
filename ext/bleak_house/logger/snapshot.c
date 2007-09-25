
#include "snapshot.h"

static VALUE rb_mBleakHouse;
static VALUE rb_cC;

/* Number of struct heaps_slots used */
static VALUE heaps_used(VALUE self) {
  return INT2FIX(rb_gc_heaps_used());
}

/* Length of the struct heaps_slots allocated */
static VALUE heaps_length(VALUE self) {
  return INT2FIX(rb_gc_heaps_length());
}

/* Counts the live objects on the heap and writes a single tagged YAML frame to the logfile. Set <tt>_specials = true</tt> if you also want to count AST nodes and var scopes; otherwise, use <tt>false</tt>. */
static VALUE snapshot(VALUE self, VALUE logfile, VALUE tag, VALUE _specials) {
  Check_Type(logfile, T_STRING);
  Check_Type(tag, T_STRING);

  RVALUE *p, *pend;
  struct heaps_slot * heaps = rb_gc_heap_slots();
  ID id;

  int specials = RTEST(_specials);

  FILE *obj_log = fopen(StringValueCStr(logfile), "r");
  int is_new;
  if (!(is_new = (obj_log == NULL)))
    fclose(obj_log);

  if ((obj_log = fopen(StringValueCStr(logfile), "a+")) == NULL)
    rb_raise(rb_eRuntimeError, "couldn't open snapshot file");

  if (is_new) 
    fprintf(obj_log, "---\n");
  fprintf(obj_log, "- - %i\n", time(0));
  VALUE mem = rb_funcall(self, rb_intern("mem_usage"), 0);
  fprintf(obj_log, "  - \"memory usage/swap\": %i\n", NUM2INT(RARRAY_PTR(mem)[0]));
  fprintf(obj_log, "    \"memory usage/real\": %i\n", NUM2INT(RARRAY_PTR(mem)[1]));
  
  int current_pos = 0;  
  int filled_slots = 0;
  int free_slots = 0;

  fprintf(obj_log, "    \"%s\":\n", StringValueCStr(tag));

  int i, j;
  for (i = 0; i < rb_gc_heaps_used(); i++) {
    p = heaps[i].slot;
    pend = p + heaps[i].limit;
    for (; p < pend; p++) {
      if (p->as.basic.flags) { /* always 0 for freed objects */
        filled_slots ++;
        switch (TYPE(p)) {
          case T_NONE:
              if (specials) fprintf(obj_log , "    - %lu: _none\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          case T_BLKTAG:
              if (specials) fprintf(obj_log , "    - %lu: _blktag\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          case T_UNDEF:
              if (specials) fprintf(obj_log , "    - %lu: _undef\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          case T_VARMAP:
              if (specials) fprintf(obj_log , "    - %lu: _varmap\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          case T_SCOPE:
              if (specials) fprintf(obj_log , "    - %lu: _scope\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          case T_NODE:
              if (specials) fprintf(obj_log , "    - %lu: _node\n", FIX2ULONG(rb_obj_id((VALUE)p)));
              break;
          default:
            if (!p->as.basic.klass) {
              fprintf(obj_log , "    - %lu: _unknown", FIX2ULONG(rb_obj_id((VALUE)p)));
            } else {
              fprintf(obj_log , "    - %lu: %s\n", FIX2ULONG(rb_obj_id((VALUE)p)), rb_obj_classname((VALUE)p));
            }
        }
      } else {
        free_slots ++;
      }
    }
  }
  
  printf("%ld", rb_parse_sym_tbl()->num_entries);
    
  fprintf(obj_log, "    \"heap usage/filled slots\": %i\n", filled_slots);
  fprintf(obj_log, "    \"heap usage/free slots\": %i\n", free_slots);
  fclose(obj_log);
  
  /* request GC run */          
  rb_funcall(rb_mGC, rb_intern("start"), 0); 
  return Qtrue;
}

void
Init_snapshot()
{
  rb_mBleakHouse = rb_define_module("BleakHouse");
  rb_cC = rb_define_class_under(rb_mBleakHouse, "Logger", rb_cObject);
  rb_define_method(rb_cC, "snapshot", snapshot, 3);
  rb_define_method(rb_cC, "heaps_used", heaps_used, 0);
  rb_define_method(rb_cC, "heaps_length", heaps_length, 0);
}
