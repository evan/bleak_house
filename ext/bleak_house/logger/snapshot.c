
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

/* Counts the live objects on the heap and in the symbol table and writes a single tagged YAML frame to the logfile. Set <tt>_specials = true</tt> if you also want to count AST nodes and var scopes; otherwise, use <tt>false</tt>. */
static VALUE snapshot(VALUE self, VALUE _logfile, VALUE tag, VALUE _specials) {
  Check_Type(_logfile, T_STRING);
  Check_Type(tag, T_STRING);

  RVALUE *obj, *obj_end;
  st_table_entry *sym, *sym_end;
  
  struct heaps_slot * heaps = rb_gc_heap_slots();
  struct st_table * sym_tbl = rb_parse_sym_tbl();

  int specials = RTEST(_specials);

  /* see if the logfile exists already */
  FILE *logfile = fopen(StringValueCStr(_logfile), "r");
  int is_new;
  if (!(is_new = (logfile == NULL)))
    fclose(logfile);

  /* reopen for writing */
  if ((logfile = fopen(StringValueCStr(_logfile), "a+")) == NULL)
    rb_raise(rb_eRuntimeError, "couldn't open snapshot file");

  /* write the yaml header */
  if (is_new) 
    fprintf(logfile, "---\n");
  fprintf(logfile, "%i:\n", time(0));
  
  /* get and write the memory usage */
  VALUE mem = rb_funcall(self, rb_intern("mem_usage"), 0);
  fprintf(logfile, "  \"memory usage/swap\": %i\n", NUM2INT(RARRAY_PTR(mem)[0]));
  fprintf(logfile, "  \"memory usage/real\": %i\n", NUM2INT(RARRAY_PTR(mem)[1]));
  
  int current_pos = 0;  
  int filled_slots = 0;
  int free_slots = 0;

  /* write the tag header */
  fprintf(logfile, "  \"%s\":\n", StringValueCStr(tag));

  int i, j;
  
  /* walk the heap */
  for (i = 0; i < rb_gc_heaps_used(); i++) {
    obj = heaps[i].slot;
    obj_end = obj + heaps[i].limit;
    for (; obj < obj_end; obj++) {
      if (obj->as.basic.flags) { /* always 0 for freed objects */
        filled_slots ++;
        switch (TYPE(obj)) {
          case T_NONE:
              if (specials) fprintf(logfile , "     %lu: _none\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          case T_BLKTAG:
              if (specials) fprintf(logfile , "     %lu: _blktag\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          case T_UNDEF:
              if (specials) fprintf(logfile , "     %lu: _undef\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          case T_VARMAP:
              if (specials) fprintf(logfile , "     %lu: _varmap\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          case T_SCOPE:
              if (specials) fprintf(logfile , "     %lu: _scope\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          case T_NODE:
              if (specials) fprintf(logfile , "     %lu: _node\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
              break;
          default:
            if (!obj->as.basic.klass) {
              fprintf(logfile , "     %lu: _unknown\n", FIX2ULONG(rb_obj_id((VALUE)obj)));
            } else {
              fprintf(logfile , "     %lu: %s\n", FIX2ULONG(rb_obj_id((VALUE)obj)), rb_obj_classname((VALUE)obj));
            }
        }
      } else {
        free_slots ++;
      }
    }
  }
  
  /* walk the symbol table */
  for (i = 0; i < sym_tbl->num_bins; i++) {
    for (sym = sym_tbl->bins[i]; sym != 0; sym = sym->next) {
      fprintf(logfile, "     %lu: Symbol\n", sym->record);
    }
  }
    
  fprintf(logfile, "  \"heap usage/filled slots\": %i\n", filled_slots);
  fprintf(logfile, "  \"heap usage/free slots\": %i\n", free_slots);
  fclose(logfile);
  
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
