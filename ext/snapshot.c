#include <time.h>
#include "snapshot.h"

static VALUE rb_mB;
static VALUE rb_cC;

/* Number of filled <tt>heaps_slots</tt> */
static VALUE heaps_used(VALUE self) {
  return INT2FIX(rb_gc_heaps_used());
}

/* Number of allocated <tt>heaps_slots</tt> */
static VALUE heaps_length(VALUE self) {
  return INT2FIX(rb_gc_heaps_length());
}

/* Inner method; call BleakHouse.snapshot instead. */
static VALUE ext_snapshot(VALUE self, VALUE _logfile, VALUE _gc_runs) {
  Check_Type(_logfile, T_STRING);
  Check_Type(_gc_runs, T_FIXNUM);

  RVALUE *obj, *obj_end;
  st_table_entry *sym;

  struct heaps_slot * heaps = rb_gc_heap_slots();
  struct st_table * sym_tbl = rb_parse_sym_tbl();

  /* see if the logfile exists already */
  FILE *logfile = fopen(StringValueCStr(_logfile), "r");
  int is_new;
  if (!(is_new = (logfile == NULL)))
    fclose(logfile);

  /* reopen for writing */
  if ((logfile = fopen(StringValueCStr(_logfile), "w")) == NULL)
    rb_raise(rb_eRuntimeError, "couldn't open snapshot file");

  int filled_slots = 0;
  int free_slots = 0;

  int i;
  int gc_runs = FIX2INT(_gc_runs);
  char * chr;

  for (i = 0; i < gc_runs; i++) {
    /* request GC run */
    rb_funcall(rb_mGC, rb_intern("start"), 0);
    rb_thread_schedule();
  }
  fprintf(logfile, "%i GC runs performed before dump\n", gc_runs);

  /* walk the heap */
  for (i = 0; i < rb_gc_heaps_used(); i++) {
    obj = heaps[i].slot;
    obj_end = obj + heaps[i].limit;
    for (; obj < obj_end; obj++) {
      if (obj->as.basic.flags) { /* always 0 for freed objects */
        filled_slots ++;

        /* write the source file*/
        if (obj->file) {
          chr = obj->file;
          if (*chr != '\0') {
            fprintf(logfile, "%s", obj->file);
          } else {
            fprintf(logfile, "__empty__");
          }
        } else {
          fprintf(logfile, "__null__");
        }

        /* write the source line */
        fprintf(logfile, ":");
        if (obj->line) {
          fprintf(logfile, "%i", obj->line);
        } else {
          fprintf(logfile, "__null__");
        }

        /* write the class */
        fprintf(logfile, ":");
        switch (TYPE(obj)) {
          case T_NONE:
              fprintf(logfile, "__none__"); break;
          case T_BLKTAG:
              fprintf(logfile, "__blktag__"); break;
          case T_UNDEF:
              fprintf(logfile, "__undef__"); break;
          case T_VARMAP:
              fprintf(logfile, "__varmap__"); break;
          case T_SCOPE:
              fprintf(logfile, "__scope__"); break;
          case T_NODE:
              fprintf(logfile, "__node__"); break;
          default:
            if (!obj->as.basic.klass) {
              fprintf(logfile, "__unknown__");
            } else {
              fprintf(logfile, rb_obj_classname((VALUE)obj));
            }
        }

        /* write newline */
        fprintf(logfile, "\n");
      } else {
        free_slots ++;
      }
    }
  }

  /* walk the symbol table */
  /* hashed = lookup_builtin("Symbol");
  for (i = 0; i < sym_tbl->num_bins; i++) {
    for (sym = sym_tbl->bins[i]; sym != 0; sym = sym->next) {
      fprintf(logfile, "%i,%lu\n", hashed + 1, sym->record);
    }
  } */

  fprintf(logfile, "%i filled\n", filled_slots);
  fprintf(logfile, "%i free\n", free_slots);
  fclose(logfile);

  return Qnil;
}


/*

This class performs the actual object logging of BleakHouse. To use it directly, you need to make calls to BleakHouse.snapshot.

By default, BleakHouse records a snapshot on exit. You can disable this by setting the environment variable <tt>NO_EXIT_HANDLER</tt> before startup.

It is also possible to externally trigger the snapshot at any time by sending <tt>SIGUSR2</tt> to the process.

== Example

At the start of your app, put:
  require 'rubygems'
  require 'bleak_house'
  $logfile = "/path/to/logfile"

Run your app. Once it exits, analyze your data:
  bleak /path/to/logfile

*/
void
Init_snapshot()
{
  rb_mB = rb_define_module("BleakHouse");
  rb_define_singleton_method(rb_mB, "ext_snapshot", ext_snapshot, 2);
  rb_define_singleton_method(rb_mB, "heaps_used", heaps_used, 0);
  rb_define_singleton_method(rb_mB, "heaps_length", heaps_length, 0);
}
