#include <utility>
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "semant.h"
#include "utilities.h"

extern int semant_debug;
extern char *curr_filename;

//////////////////////////////////////////////////////////////////////
//
// Symbols
//
// For convenience, a large number of symbols are predefined here.
// These symbols include the primitive type and method names, as well
// as fixed names used by the runtime system.
//
//////////////////////////////////////////////////////////////////////
static Symbol arg, arg2, Bool, concat, cool_abort, copy, Int, in_int, in_string, IO, length, Main,
		main_meth, No_class, No_type, Object, out_int, out_string, prim_slot, self, SELF_TYPE, Str,
		str_field, substr, type_name, val;
//
// Initializing the predefined symbols.
//
static void initialize_constants(void) {
	arg = idtable.add_string("arg");
	arg2 = idtable.add_string("arg2");
	Bool = idtable.add_string("Bool");
	concat = idtable.add_string("concat");
	cool_abort = idtable.add_string("abort");
	copy = idtable.add_string("copy");
	Int = idtable.add_string("Int");
	in_int = idtable.add_string("in_int");
	in_string = idtable.add_string("in_string");
	IO = idtable.add_string("IO");
	length = idtable.add_string("length");
	Main = idtable.add_string("Main");
	main_meth = idtable.add_string("main");
	//   _no_class is a symbol that can't be the name of any
	//   user-defined class.
	No_class = idtable.add_string("_no_class");
	No_type = idtable.add_string("_no_type");
	Object = idtable.add_string("Object");
	out_int = idtable.add_string("out_int");
	out_string = idtable.add_string("out_string");
	prim_slot = idtable.add_string("_prim_slot");
	self = idtable.add_string("self");
	SELF_TYPE = idtable.add_string("SELF_TYPE");
	Str = idtable.add_string("String");
	str_field = idtable.add_string("_str_field");
	substr = idtable.add_string("substr");
	type_name = idtable.add_string("type_name");
	val = idtable.add_string("_val");
}

ClassTable::ClassTable(Classes classes) :
	semant_errors(0), error_stream(cerr) {

	if (semant_debug)
		cerr << "# Classes: " << classes->len() << endl;

	class_table = new SymbolTable<Symbol, class__class> ();
	class_table->enterscope();

	for (int i = classes->first(); classes->more(i); i = classes->next(i)) {
		class__class *aclass = (class__class *) (classes->nth(i));
		if (semant_debug)
			aclass->dump(cerr, 0);
		class_map.insert(std::make_pair(aclass->get_parent(), aclass->get_name()));

		//report duplication
		if (class_table->probe(aclass->get_name()) != NULL)
			semant_error(aclass, NULL, DUPLICATE);

		class_table->addid(aclass->get_name(), aclass);

		//report disallowed re-declaration
		if (aclass->get_name() == No_class || aclass->get_name() == Object || aclass->get_name()
				== IO || aclass->get_name() == Int || aclass->get_name() == Str||aclass->get_name() == SELF_TYPE)
			semant_error(aclass, NULL, BASE_REDEF);

	}

	install_basic_classes();
	inheritance_check();

}
void ClassTable::inheritance_check() {
	if (semant_debug)
		cerr << "inheritance checking" << endl;

	std::map<Symbol, int> in_degree;
	for (std::multimap<Symbol, Symbol>::iterator it = class_map.begin(); it != class_map.end(); ++it) {
		if (semant_debug)
			cerr << it->first << ": " << it->second << endl;

		//report disallowed inheritance
		if (it->first == Int || it->first == Str || it->first == Bool)
			semant_error(class_table->lookup((*it).second), class_table->lookup((*it).first),
					ILLEGAL_INHERIT);

		in_degree[it->second]++;
	}

	std::set<Symbol> class_set;
	inheritance_traverse(No_class, class_set);
	if (semant_debug)
		cerr << "inheritance tree has " << class_set.size() << " nodes" << endl;

	//report undeclared classes
	if (class_set.size() < class_map.size() + 1) {
		for (std::multimap<Symbol, Symbol>::iterator it = class_map.begin(); it != class_map.end(); ++it)
			if (!class_set.count(it->first) && !in_degree[it->first]) {
				semant_error(class_table->lookup(it->second), NULL, UNDEF_INHERIT);
				inheritance_traverse(it->first, class_set);
			}

		for (std::multimap<Symbol, Symbol>::iterator it = class_map.begin(); it != class_map.end(); ++it)
			if (!class_set.count(it->first))
				semant_error(class_table->lookup(it->first), NULL, CYCLE);
	}
}

void ClassTable::inheritance_traverse(Symbol symbol, std::set<Symbol> &visited) {
	if (visited.count(symbol)) {
		semant_error(class_table->lookup(symbol), NULL, CYCLE);
		return;
	}
	visited.insert(symbol);
	std::pair<std::multimap<Symbol, Symbol>::iterator, std::multimap<Symbol, Symbol>::iterator>
			range = class_map.equal_range(symbol);

	for (std::multimap<Symbol, Symbol>::iterator it = range.first; it != range.second; ++it)
		inheritance_traverse(it->second, visited);
}

//collect declarations for methods and objects
void ClassTable::collect_declaration() {
	method_table = new SymbolTable<Symbol, method_class> ();
	object_table = new SymbolTable<Symbol, Symbol> ();
	ast_traverse(Object);
}

//very similar to inheritance traversion
//but we are sure the inheritance graph is well-formed this time
void ClassTable::ast_traverse(Symbol symbol) {
	method_table->enterscope();
	object_table->enterscope();
	class__class *myclass = class_table->lookup(symbol);

	//environment scan
	if(myclass->scan(object_table, method_table, class_table)>0)
		semant_error();

	std::pair<std::multimap<Symbol, Symbol>::iterator, std::multimap<Symbol, Symbol>::iterator>
			range = class_map.equal_range(symbol);

	for (std::multimap<Symbol, Symbol>::iterator it = range.first; it != range.second; ++it)
		ast_traverse((*it).second);

	object_table->exitscope();
	method_table->exitscope();
}

void ClassTable::install_basic_classes() {

	// The tree package uses these globals to annotate the classes built below.
	// curr_lineno  = 0;
	Symbol filename = stringtable.add_string("<basic class>");

	// The following demonstrates how to create dummy parse trees to
	// refer to basic Cool classes.  There's no need for method
	// bodies -- these are already built into the runtime system.

	// IMPORTANT: The results of the following expressions are
	// stored in local variables.  You will want to do something
	// with those variables at the end of this method to make this
	// code meaningful.

	//
	// The Object class has no parent class. Its methods are
	//        abort() : Object    aborts the program
	//        type_name() : Str   returns a string representation of class name
	//        copy() : SELF_TYPE  returns a copy of the object
	//
	// There is no need for method bodies in the basic classes---these
	// are already built in to the runtime system.

	Class_ Object_class = class_(Object, No_class, append_Features(append_Features(single_Features(
			method(cool_abort, nil_Formals(), Object, no_expr())), single_Features(method(
			type_name, nil_Formals(), Str, no_expr()))), single_Features(method(copy,
			nil_Formals(), SELF_TYPE, no_expr()))), filename);

	class_map.insert(std::make_pair(No_class, Object));
	class_table->addid(Object, (class__class *) Object_class);
	//
	// The IO class inherits from Object. Its methods are
	//        out_string(Str) : SELF_TYPE       writes a string to the output
	//        out_int(Int) : SELF_TYPE            "    an int    "  "     "
	//        in_string() : Str                 reads a string from the input
	//        in_int() : Int                      "   an int     "  "     "
	//
	Class_ IO_class =
			class_(IO, Object, append_Features(append_Features(append_Features(single_Features(
					method(out_string, single_Formals(formal(arg, Str)), SELF_TYPE, no_expr())),
					single_Features(method(out_int, single_Formals(formal(arg, Int)), SELF_TYPE,
							no_expr()))), single_Features(method(in_string, nil_Formals(), Str,
					no_expr()))), single_Features(method(in_int, nil_Formals(), Int, no_expr()))),
					filename);

	class_map.insert(std::make_pair(Object, IO));
	class_table->addid(IO, (class__class *) IO_class);
	//
	// The Int class has no methods and only a single attribute, the
	// "val" for the integer.
	//
	Class_ Int_class = class_(Int, Object, single_Features(attr(val, prim_slot, no_expr())),
			filename);

	class_map.insert(std::make_pair(Object, Int));
	class_table->addid(Int, (class__class *) Int_class);
	//
	// Bool also has only the "val" slot.
	//
	Class_ Bool_class = class_(Bool, Object, single_Features(attr(val, prim_slot, no_expr())),
			filename);

	class_map.insert(std::make_pair(Object, Bool));
	class_table->addid(Bool, (class__class *) Bool_class);
	//
	// The class Str has a number of slots and operations:
	//       val                                  the length of the string
	//       str_field                            the string itself
	//       length() : Int                       returns length of the string
	//       concat(arg: Str) : Str               performs string concatenation
	//       substr(arg: Int, arg2: Int): Str     substring selection
	//
	Class_ Str_class = class_(Str, Object, append_Features(append_Features(append_Features(
			append_Features(single_Features(attr(val, Int, no_expr())), single_Features(attr(
					str_field, prim_slot, no_expr()))), single_Features(method(length,
					nil_Formals(), Int, no_expr()))), single_Features(method(concat,
			single_Formals(formal(arg, Str)), Str, no_expr()))), single_Features(method(substr,
			append_Formals(single_Formals(formal(arg, Int)), single_Formals(formal(arg2, Int))),
			Str, no_expr()))), filename);

	class_map.insert(std::make_pair(Object, Str));
	class_table->addid(Str, (class__class *) Str_class);

}

void ClassTable::semant_error(Class_ current_class, Class_ parent_class, Msg msg) {
	char e_msg[1000];
	char* class_name;
	switch (msg) {
	case BASE_REDEF:
		sprintf(e_msg, "Redefinition of basic class %s", current_class->get_name()->get_string());
		break;
	case CYCLE:
		sprintf(e_msg, "Class %s, or an ancestor of %s, is involved in an inheritance cycle",
				current_class->get_name()->get_string(), current_class->get_name()->get_string());
		break;
	case DUPLICATE:
		sprintf(e_msg, "Class %s was previously defined", current_class->get_name()->get_string());
		break;
	case ILLEGAL_INHERIT:
		sprintf(e_msg, "Class %s cannot inherit class %s", current_class->get_name()->get_string(),
				parent_class->get_name()->get_string());
		break;
	case UNDEF_INHERIT:
		sprintf(e_msg, "Class %s inherits from an undefined class %s",
				current_class->get_name()->get_string(), current_class->get_parent()->get_string());
		break;
	default:
		strcpy(e_msg, "");
	}
	semant_error(current_class) << e_msg << endl;
}

////////////////////////////////////////////////////////////////////
//
// semant_error is an overloaded function for reporting errors
// during semantic analysis.  There are three versions:
//
//    ostream& ClassTable::semant_error()
//
//    ostream& ClassTable::semant_error(Class_ c)
//       print line number and filename for `c'
//
//    ostream& ClassTable::semant_error(Symbol filename, tree_node *t)
//       print a line number and filename
//
///////////////////////////////////////////////////////////////////
ostream& ClassTable::semant_error(Class_ c) {
	return semant_error(c->get_filename(), c);
}

ostream& ClassTable::semant_error(Symbol filename, tree_node *t) {
	error_stream << filename << ":" << t->get_line_number() << ": ";
	return semant_error();
}

ostream& ClassTable::semant_error() {
	semant_errors++;
	return error_stream;
}

/*   This is the entry point to the semantic checker.

 Your checker should do the following two things:

 1) Check that the program is semantically correct
 2) Decorate the abstract syntax tree with type information
 by setting the `type' field in each Expression node.
 (see `tree.h')

 You are free to first do 1), make sure you catch all semantic
 errors. Part 2) can be done in a second stage, when you want
 to build mycoolc.
 */
void program_class::semant() {
	initialize_constants();

	/* ClassTable constructor may do some semantic analysis */
	ClassTable *classtable = new ClassTable(classes);
	if (classtable->errors()) {
		cerr << "Compilation halted due to static semantic errors." << endl;
		exit(1);
	}

	classtable->collect_declaration();
	if (classtable->errors()) {
		cerr << "Compilation halted due to static semantic errors." << endl;
		exit(1);
	}

	if (semant_debug)
		cerr << "starting type check" << endl;
	if (this->check_type(cerr, classtable->get_class_table()) > 0) {
		cerr << "Compilation halted due to static semantic errors." << endl;
		exit(1);
	}
}
