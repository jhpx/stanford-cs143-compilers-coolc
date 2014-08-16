#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <math.h>
#include "cool-tree.h"

#define Max(a, b)       (((a) > (b)) ? (a) : (b))

class Class_graph_node {
public:
	Symbol current_symbol;
	Symbol parent_symbol;
	Class_graph_node *next, *parent;
	Class_graph_node **children;
	int numChildren;
	Class_ current_class;

	bool is_tail, is_root;

	Class_graph_node(Class_ c1) {
		is_root = false;
		is_tail = false;
		next = NULL;
		parent = NULL;
		current_class = c1;
		numChildren = 0;
		current_symbol = c1->get_name();
		parent_symbol = c1->get_parent();
	}

	void add_child(Class_graph_node* const c1) {

		Class_graph_node **temp = new Class_graph_node *[numChildren + 1];

		for (int i = 0; i < numChildren; i++) {
			temp[i] = children[i];
		}
		temp[numChildren] = c1;

		if (numChildren > 0)
			delete[] children;
		children = temp;

		numChildren++;

	}

	bool has_node(Symbol const sym) {
		//    cout<<"Finding... "<<sym<<", "<<current_symbol->get_string()<<", "<<current_symbol->get_len()<<", "<<sym->get_string()<<", "<<sym->get_len()<<endl;
		int max_length = Max(current_symbol->get_len(),sym->get_len());
		if (sym->equal_string(current_symbol->get_string(), max_length)) {
			return true;
		} else {
			if (is_tail) {
				return false;
			} else {
				return next->has_node(sym);
			}
		}
	}

	bool has_child(Symbol const sym) {
		for (int i = 0; i < numChildren; i++) {
			if (children[i]->has_node(sym)) {
				return true;
			}
		}
		return false;
	}

	Class_graph_node* find_node(Symbol const sym) {
			//    cout<<"Finding... "<<sym<<", "<<current_symbol->get_string()<<", "<<current_symbol->get_len()<<", "<<sym->get_string()<<", "<<sym->get_len()<<endl;
			int max_length = Max(current_symbol->get_len(),sym->get_len());
			if (sym->equal_string(current_symbol->get_string(), max_length)) {
				return this;
			} else {
				if (is_tail) {
					return NULL;
				} else {
					return next->find_node(sym);
				}
			}
		}

};

class Class_graph {
private:
	Class_graph_node *root;
	Class_graph_node *tail;
	int numNodes;

public:
	Class_graph(Class_graph_node *c1) {
		//cout << "Adding: " << c1->current_symbol << ", to parent: " << c1->parent_symbol << endl;
		numNodes = 1;
		root = c1;
		tail = root;
		root->is_tail = true;
		root->is_root = true;
	}

	void add_node(Class_graph_node *c1) {
		//cout << "Adding: " << c1->current_symbol << ", to parent: " << c1->parent_symbol << endl;
		c1->parent = root;
		root->add_child(c1);

		tail->next = c1;
		tail->is_tail = false;
		tail = c1;
		tail->is_tail = true;
		numNodes++;

	}

	Class_graph_node *get_last_node() {
		return tail;
	}

	Class_graph_node *get_first_node() {
		return root;
	}

	int build_class_graph(Classes classes) {

		for (int i = classes->first(); classes->more(i); i = classes->next(i)) {
			if (root->find_node(classes->nth(i)->get_name())) {
				cerr << "Error(1): Invalid duplicated name, "
						<< classes->nth(i)->get_name() << endl;
				return -1;
			} else {
				//cout << "Adding: " << classes->nth(i)->get_name() << ", to parent: " << classes->nth(i)->get_parent()	<< endl;
				Class_graph_node *n = new Class_graph_node(classes->nth(i));

				for (Class_graph_node *p = root; p != NULL; p = p->next) {

					if (!p->is_root) {
						//check if new node n is parent to existing node p
						//cout << "Checking node child: " << n->current_symbol << ", against: " << p->parent_symbol << endl;
						int max_length = Max(n->current_symbol->get_len(),
								p->parent_symbol->get_len());

						if (p->parent_symbol->equal_string(
								n->current_symbol->get_string(), max_length)) {
							//cout << "Found node child!" << endl;
							p->parent = n;
							n->add_child(p);
						}
					}
					//check if existing node p is parent to new node n
					// cout << "Checking node parent: " << n->parent_symbol	<< ", against: " << p->current_symbol << endl;
					int max_length = Max(n->parent_symbol->get_len(),
							p->current_symbol->get_len());

					if (n->parent_symbol->equal_string(
							p->current_symbol->get_string(), max_length)) {
						// cout << "Found node parent!" << endl;
						n->parent = p;
						p->add_child(n);
					}
				}

				//add reference to node to last node and incriment number of nodes
				tail->next = n;
				tail->is_tail = false;
				tail = n;
				tail->is_tail = true;
				numNodes++;

			}
		}
		return 0;
	}

};
