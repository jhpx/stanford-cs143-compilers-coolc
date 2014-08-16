#ifndef SEMANT_H_
#define SEMANT_H_

#include <assert.h>
#include <iostream>  
#include "cool-tree.h"
#include "stringtab.h"
#include "list.h"
#include "symtab.h"
#include <map>
#include <set>

#define TRUE 1
#define FALSE 0

class ClassTable;
typedef ClassTable *ClassTableP;
typedef SymbolTable<Symbol, method_class> *FuncScope;
typedef SymbolTable<Symbol, tree_node> *ObjScope;

enum Msg {BASE_REDEF, ILLEGAL_INHERIT, UNDEF_INHERIT, DUPLICATE, NO_PARENT, CYCLE};
// This is a structure that may be used to contain the semantic
// information such as the inheritance graph.  You may use it or not as
// you like: it is only here to provide a container for the supplied
// methods.

class ClassTable {
private:
  int semant_errors;
  void install_basic_classes();
  void inheritance_check();
  void inheritance_traverse(Symbol, std::set<Symbol> &);
  void ast_traverse(Symbol symbol);
  ostream& error_stream;

  std::multimap<Symbol, Symbol>     class_map;     //maps inheritance: parent -> child
  SymbolTable<Symbol, Symbol>       *object_table; //object name -> static type
  SymbolTable<Symbol, method_class> *method_table; //method name -> method address
  SymbolTable<Symbol, class__class> *class_table;  //class name -> class address


public:
  ClassTable(Classes);
  int errors() { return semant_errors; }
  ostream& semant_error();
  ostream& semant_error(Class_ c);
  ostream& semant_error(Symbol filename, tree_node *t);
  void semant_error(Class_ c1, Class_ c2, Msg msg);

  void collect_declaration();
  SymbolTable<Symbol, class__class>* get_class_table() { return class_table; }
};


#endif

