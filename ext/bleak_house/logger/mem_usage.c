
#include "mem_usage.h"

static VALUE rb_mBleakHouse;
static VALUE rb_cC;

/* Number of struct heaps_slots used */
static VALUE heaps_used() {
  return INT2FIX(rb_gc_heaps_used());
}

/* Length of the struct heaps_slots allocated */
static VALUE heaps_length() {
  return INT2FIX(rb_gc_heaps_length());
}

/* Counts the live objects on the heap and writes a single tagged YAML frame to the logfile. Set <tt>_specials = true</tt> if you also want to count AST nodes and var scopes; otherwise, use <tt>false</tt>. */
static VALUE snapshot(VALUE self, VALUE logfile, VALUE tag, VALUE _specials) {
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
    fprintf(obj_log, "---\n");
  fprintf(obj_log, "- - %i\n", time(0));
  VALUE mem = rb_funcall(self, rb_intern("mem_usage"), 0);
  fprintf(obj_log, "  - :\"memory usage/swap\": %i\n", NUM2INT(RARRAY_PTR(mem)[0]));
  fprintf(obj_log, "    :\"memory usage/real\": %i\n", NUM2INT(RARRAY_PTR(mem)[1]));
  
  /* haha */
  char tags[MAX_UNIQ_TAGS][MAX_TAG_LENGTH];
  char current_tag[2048];
  int counts[MAX_UNIQ_TAGS];
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
          case T_NONE:
              if (specials) sprintf(current_tag , "%s::::_none", StringValueCStr(tag));
              break;
          case T_BLKTAG:
              if (specials) sprintf(current_tag , "%s::::_blktag", StringValueCStr(tag));
              break;
          case T_UNDEF:
              if (specials) sprintf(current_tag , "%s::::_undef", StringValueCStr(tag));
              break;
          case T_VARMAP:
              if (specials) sprintf(current_tag , "%s::::_varmap", StringValueCStr(tag));
              break;
          case T_SCOPE:
              if (specials) sprintf(current_tag , "%s::::_scope", StringValueCStr(tag));
              break;
          case T_NODE:
              if (specials) sprintf(current_tag , "%s::::_node", StringValueCStr(tag));
              break;                
          default:
            if (!p->as.basic.klass) {
              sprintf(current_tag , "%s::::_unknown", StringValueCStr(tag));
            } else {
              sprintf(current_tag , "%s::::%s", StringValueCStr(tag), rb_obj_classname((VALUE)p));
            }
        }
        if (strlen(current_tag) > MAX_TAG_LENGTH)
          rb_raise(rb_eRuntimeError, "tag + classname too big; increase MAX_TAG_LENGTH and recompile.");
        if (strcmp(current_tag, "")) {
          for (j = 0; j < current_pos; j++) {
            if (!strcmp(tags[j], current_tag)) {
              counts[j] ++;
              break;
            }
          }
          if (j == current_pos) {
            /* found a new one */
            if (current_pos == MAX_UNIQ_TAGS)
              rb_raise(rb_eRuntimeError, "exhausted tag array; increase MAX_UNIQ_TAGS and recompile.");
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
  fprintf(obj_log, "    :\"heap usage/filled slots\": %i\n", filled_slots);
  fprintf(obj_log, "    :\"heap usage/free slots\": %i\n", free_slots);
  for (j = 0; j < current_pos; j++) {
    fprintf(obj_log, "    :\"%s\": %i\n", tags[j], counts[j]);
  }
  fclose(obj_log);
  
  /* request GC run */          
  rb_funcall(rb_mGC, rb_intern("start"), 0); 
  /* to get a custom module: rb_const_get(parentModule, "ModuleName") 
      parent module can be something like rb_mKernel for the toplevel */
  return Qtrue;
}

void
Init_logger()
{
  rb_mBleakHouse = rb_define_module("BleakHouse");
  rb_cC = rb_define_class_under(rb_mBleakHouse, "Logger", rb_cObject);
  rb_define_method(rb_cC, "snapshot", snapshot, 4);
  rb_define_method(rb_cC, "heaps_used", heaps_used, 0);
  rb_define_method(rb_cC, "heaps_length", heaps_length, 0);
}
