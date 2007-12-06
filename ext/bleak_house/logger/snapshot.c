#include <time.h>
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

/* Count the live objects on the heap and in the symbol table and write a CSV frame to <tt>_logfile</tt>. Set <tt>_specials = true</tt> if you also want to count AST nodes and var scopes; otherwise, use <tt>false</tt>. Note that common classes in the CSV output are hashed to small integers in order to save space.*/
static VALUE snapshot(VALUE self, VALUE _logfile, VALUE tag, VALUE _specials) {
  Check_Type(_logfile, T_STRING);
  Check_Type(tag, T_STRING);

  RVALUE *obj, *obj_end;
  st_table_entry *sym; 
  
  struct heaps_slot * heaps = rb_gc_heap_slots();
  struct st_table * sym_tbl = rb_parse_sym_tbl();

  int specials = RTEST(_specials);
  int hashed;

  /* see if the logfile exists already */
  FILE *logfile = fopen(StringValueCStr(_logfile), "r");
  int is_new;
  if (!(is_new = (logfile == NULL)))
    fclose(logfile);

  /* reopen for writing */
  if ((logfile = fopen(StringValueCStr(_logfile), "a+")) == NULL)
    rb_raise(rb_eRuntimeError, "couldn't open snapshot file");

  /* write the time */
  fprintf(logfile, "-1,%li\n", time(0));
  
  /* get and write the memory usage */
  VALUE mem = rb_funcall(self, rb_intern("mem_usage"), 0);
  fprintf(logfile, "-2,%li\n", NUM2INT(RARRAY_PTR(mem)[0]));
  fprintf(logfile, "-3,%li\n", NUM2INT(RARRAY_PTR(mem)[1]));
  
  int filled_slots = 0;
  int free_slots = 0;

  /* write the tag header */
  fprintf(logfile, "-4,%s\n", StringValueCStr(tag));

  int i; 
  
  /* walk the heap */
  for (i = 0; i < rb_gc_heaps_used(); i++) {
    obj = heaps[i].slot;
    obj_end = obj + heaps[i].limit;
    for (; obj < obj_end; obj++) {
      if (obj->as.basic.flags) { /* always 0 for freed objects */
        filled_slots ++;
        switch (TYPE(obj)) {
          case T_NONE:
              hashed = BUILTINS_SIZE + 0; break;
          case T_BLKTAG:
              hashed = BUILTINS_SIZE + 1; break;
          case T_UNDEF:
              hashed = BUILTINS_SIZE + 2; break;
          case T_VARMAP:
              hashed = BUILTINS_SIZE + 3; break;
          case T_SCOPE:
              hashed = BUILTINS_SIZE + 4; break;
          case T_NODE:
              hashed = BUILTINS_SIZE + 5; break;
          default:
            if (!obj->as.basic.klass) {
              hashed = BUILTINS_SIZE + 6;
            } else {
              hashed = lookup_builtin(rb_obj_classname((VALUE)obj));
            }
        }
        /* write to log */
        if (hashed < 0) {
          /* regular classname */
          fprintf(logfile, "%s,%lu\n", rb_obj_classname((VALUE)obj), FIX2ULONG(rb_obj_id((VALUE)obj)));
        } else {
          /* builtins key */
          if (specials || hashed < BUILTINS_SIZE) {
            /* 0 is not used for 'hashed' because Ruby's to_i turns any String into 0 */
            fprintf(logfile, "%i,%lu\n", hashed + 1, FIX2ULONG(rb_obj_id((VALUE)obj)));
          }
        }
      } else {
        free_slots ++;
      }
    }
  }
  
  /* walk the symbol table */
  hashed = lookup_builtin("Symbol");
  for (i = 0; i < sym_tbl->num_bins; i++) {
    for (sym = sym_tbl->bins[i]; sym != 0; sym = sym->next) {
      fprintf(logfile, "%i,%lu\n", hashed + 1, sym->record);
    }
  }
    
  fprintf(logfile, "-5,%i\n", filled_slots);
  fprintf(logfile, "-6,%i\n", free_slots);
  fclose(logfile);
    
  rb_funcall(rb_mGC, rb_intern("start"), 0); /* request GC run */
  return Qtrue;
}

int lookup_builtin(char * name) {
  int i;
  for (i = 0; i < BUILTINS_SIZE; i++) {
    if (!strcmp(builtins[i], name)) return i;      
  }
  return -1;
}

/*

This class performs the actual object logging of BleakHouse. To use it directly, you need to make calls to BleakHouse::Logger#snapshot. 

== Example

At the start of your app, put:
  require 'rubygems'
  require 'bleak_house'
  $memlogger = BleakHouse::Logger.new
  File.delete($logfile = "/path/to/logfile") rescue nil

Now, at the points of interest, put:
  $memlogger.snapshot($logfile, "tag/subtag", false)

Run your app. Once you are done, analyze your data:
  bleak /path/to/logfile
  
*/
void
Init_snapshot()
{
  rb_mBleakHouse = rb_define_module("BleakHouse");
  rb_cC = rb_define_class_under(rb_mBleakHouse, "Logger", rb_cObject);
  rb_define_method(rb_cC, "snapshot", snapshot, 3);
  rb_define_method(rb_cC, "heaps_used", heaps_used, 0);
  rb_define_method(rb_cC, "heaps_length", heaps_length, 0);
}
