/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"

  extern char *curr_filename;


  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */

    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */


      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;


    #define SET_NODELOC(Current)  \
    node_lineno = Current;

    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive
    * (fictional) construct that matches a plus between two integer constants.
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):

    plus_consts : INT_CONST '+' INT_CONST

    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:

    plus_consts : INT_CONST '+' INT_CONST
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th expression with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you
      // omit the statement @$=..., bison has default rules for deciding which
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;


      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);

      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }

    */



    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */

    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */

    Program ast_root;             /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}

    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }

    /*
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.

    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283

    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/

    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison
    documentation for details). */

    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class
    %type <features> feature_list
    %type <feature> feature
    %type <formals> formal_list
    %type <formal> formal
    %type <cases> case_list
    %type <case_> case
    %type <expressions> expr_list_comma expr_list_semicolon
    %type <expression> expr let_extra

    /* Precedence declarations go here. */
    /* NOTE: the operator with the highest priority goes to the last of
       the list */
    %right IN
    %right ASSIGN /* The only right-associative operator */
    %left NOT
    %nonassoc LE '<' '='
    %left '+' '-'
    %left '*' '/'
    %left ISVOID
    %left '~'
    %left '@'
    %left '.'

    %%
    /*********************************************************************
     * Program
     *
     * Program ::= Classes
     * Save the root of the abstract syntax tree in a global variable.
     *********************************************************************/
    program
    : class_list
    { @$ = @1; SET_NODELOC(@1); ast_root = program($1); }
    ;

    /*********************************************************************
     * Classes
     *
     * Classes ::= [[Class;]]+
     * Have a Class at least.
     *********************************************************************/
    class_list
    : class ';'                /* single class */
    { @$ = @2; SET_NODELOC(@2);
      $$ = single_Classes($1); parse_results = $$; }
    | class_list class ';'     /* several classes */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Classes($1,single_Classes($2));
    parse_results = $$; }
    ;

    /*********************************************************************
     * Class
     *
     * Class ::= class TYPE [inherits TYPE] { Features }
     * If no parent is specified, the class inherits from the Object class.
     *********************************************************************/
    class
    : CLASS TYPEID '{' feature_list '}'
    { @$ = @5; SET_NODELOC(@5);
      $$ = class_($2,idtable.add_string("Object"),$4,
                  stringtable.add_string(curr_filename)); }
    | CLASS TYPEID INHERITS TYPEID '{' feature_list '}'
    { @$ = @7; SET_NODELOC(@7);
      $$ = class_($2,$4,$6,
                  stringtable.add_string(curr_filename)); }
    | error
    {}
    ;

    /*********************************************************************
     * Features
     *
     * Features ::= [[Feature;]]*
     * Can be empty.
     *********************************************************************/
    feature_list
    :                            /* empty*/
    { $$ = nil_Features();}
    | feature_list feature ';'   /* several features */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Features($1,single_Features($2)); }
    ;

    /*********************************************************************
     * Feature
     *
     * Feature ::= ID([ Formals ]) : TYPE { Expr }
     *           | ID : TYPE [ <- Expr ]
     *********************************************************************/
    feature
    : OBJECTID '(' ')' ':' TYPEID '{' expr '}'
    { @$ = @8; SET_NODELOC(@8); $$ = method($1,nil_Formals(),$5,$7); }
    | OBJECTID '(' formal_list ')' ':' TYPEID '{' expr '}'
    { @$ = @9; SET_NODELOC(@9); $$ = method($1,$3,$6,$8); }
    | OBJECTID ':' TYPEID
    { @$ = @3; SET_NODELOC(@3); $$ = attr($1,$3,no_expr()); }
    | OBJECTID ':' TYPEID ASSIGN expr
    { @$ = @5; SET_NODELOC(@5); $$ = attr($1,$3,$5); }
    | error
    {}
    ;

    /*********************************************************************
     * Formals
     *
     * Formals ::= Formal [[,Formal]]*
     * Have a Formal at least.
     *********************************************************************/
    formal_list
    : formal                    /* single formal */
    { @$ = @1; SET_NODELOC(@1);
      $$ = single_Formals($1);}
    | formal_list ',' formal    /* several formals */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Formals($1,single_Formals($3)); }
    ;

    /*********************************************************************
     * Formal
     *
     * Formal ::= ID : TYPE
     *********************************************************************/
    formal
    : OBJECTID ':' TYPEID
    { @$ = @3; SET_NODELOC(@3); $$ = formal($1,$3); }
    ;

    /*********************************************************************
     * Cases
     *
     * Cases ::= [[Case;]]+
     * Have a Case at least.
     *********************************************************************/
    case_list
    : case ';'             /* single case */
    { @$ = @2; SET_NODELOC(@2); $$ = single_Cases($1);}
    | case_list case ';'   /* several cases */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Cases($1,single_Cases($2)); }
    ;

    /*********************************************************************
     * Case
     *
     * Case ::=  ID : TYPE => Expr;
     *********************************************************************/
    case
    : OBJECTID ':' TYPEID DARROW expr
    { @$ = @5; SET_NODELOC(@5); $$ = branch($1,$3,$5); }
    ;

    /*********************************************************************
     * Expressions - semicolon
     *
     * Expressions ::=  [[Expr;]]+
     *********************************************************************/
    expr_list_semicolon
    : expr ';'                      /* single expression */
    { @$ = @2; SET_NODELOC(@2); $$ = single_Expressions($1);}
    | expr_list_semicolon expr ';'    /* several expressions */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Expressions($1,single_Expressions($2)); }
    | error ';'
    {}
    ;

    /*********************************************************************
     * Expressions - comma
     *
     * Expressions ::= Expr [[, Expr]]∗
     *********************************************************************/
    expr_list_comma
    : expr                        /* single expression */
    { @$ = @1; SET_NODELOC(@1); $$ = single_Expressions($1);}
    | expr_list_comma ',' expr    /* several expressions */
    { @$ = @3; SET_NODELOC(@3);
      $$ = append_Expressions($1,single_Expressions($3)); }
    ;


    /*********************************************************************
     * Expr - assignment
     *
     * Expr ::= ID <- Expr
     *********************************************************************/
    expr
    : OBJECTID ASSIGN expr
    { @$ = @3; SET_NODELOC(@3); $$ = assign($1,$3); }
    ;

    /*********************************************************************
     * Expr - dispatch
     *
     * Expr ::= Expr[@TYPE].ID( [ Expr [[, Expr]]∗ ] )
     *        | ID( [ Expr [[, Expr]]∗ ] )
     *********************************************************************/
    expr
    : expr '.' OBJECTID '(' ')'
    { @$ = @5; SET_NODELOC(@5);
      $$ = dispatch($1,$3,nil_Expressions()); }
    | expr '.' OBJECTID '(' expr_list_comma ')'
    { @$ = @6; SET_NODELOC(@6);
      $$ = dispatch($1,$3,$5); }
    | expr '@' TYPEID '.' OBJECTID '(' ')'
    { @$ = @7; SET_NODELOC(@7);
      $$ = static_dispatch($1,$3,$5,nil_Expressions()); }
    | expr '@' TYPEID '.' OBJECTID '(' expr_list_comma ')'
    { @$ = @8; SET_NODELOC(@8);
      $$ = static_dispatch($1,$3,$5,$7); }
    | OBJECTID '(' ')'
    { @$ = @3; SET_NODELOC(@3);
      $$ = dispatch(object(idtable.add_string("self")),$1,nil_Expressions()); }
    | OBJECTID '(' expr_list_comma ')'
    { @$ = @4; SET_NODELOC(@4);
      $$ = dispatch(object(idtable.add_string("self")),$1,$3); }
    ;

    /*********************************************************************
     * Expr - conditions
     *
     * Expr ::= if Expr then Expr else Expr ﬁ
     *********************************************************************/
    expr
    : IF expr THEN expr ELSE expr FI
    { @$ = @7; SET_NODELOC(@7); $$ = cond($2,$4,$6); }
    ;

    /*********************************************************************
     * Expr - loops
     *
     * Expr ::= while Expr loop Expr pool
     *********************************************************************/
    expr
    : WHILE expr LOOP expr POOL
    { @$ = @5; SET_NODELOC(@5); $$ = loop($2,$4); }
    ;

    /*********************************************************************
     * Expr - blocks
     *
     * Expr ::= while Expr loop Expr pool
     *********************************************************************/
    expr
    : '{' expr_list_semicolon '}'
    { @$ = @3; SET_NODELOC(@3); $$ = block($2); }
    ;

    /*********************************************************************
     * Expr - let
     *
     * Expr ::= let ID : TYPE [ <- expr ] [[, ID : TYPE [ <- expr ]]]∗ in expr
     *********************************************************************/
    expr
    : LET OBJECTID ':' TYPEID let_extra
    { @$ = @5; SET_NODELOC(@5); $$ = let($2,$4,no_expr(),$5); }
    | LET OBJECTID ':' TYPEID ASSIGN expr let_extra
    { @$ = @7; SET_NODELOC(@7); $$ = let($2,$4,$6,$7); }
    | LET error IN expr
    {}
    ;

    let_extra
    : IN expr
    { @$ = @2; SET_NODELOC(@2); $$ = $2; }
    | ',' OBJECTID ':' TYPEID let_extra
    { @$ = @5; SET_NODELOC(@5); $$ = let($2,$4,no_expr(),$5); }
    | ',' OBJECTID ':' TYPEID ASSIGN expr let_extra
    { @$ = @7; SET_NODELOC(@7); $$ = let($2,$4,$6,$7); }
    ;

    /*********************************************************************
     * Expr - case
     *
     * Expr ::= case Expr of Cases esac
     *********************************************************************/
    expr /* case */
    : CASE expr OF case_list ESAC
    { @$ = @5; SET_NODELOC(@5); $$ = typcase($2,$4); }
    ;

    /*********************************************************************
     * Expr - new
     *
     * Expr ::= new TYPE
     *********************************************************************/
    expr
    : NEW TYPEID
    { @$ = @2; SET_NODELOC(@2); $$ = new_($2); }
    ;

    /*********************************************************************
     * Expr - isvoid
     *
     * Expr ::= isvoid Expr
     *********************************************************************/
    expr
    : ISVOID expr
    { @$ = @2; SET_NODELOC(@2); $$ = isvoid($2); }
    ;

    /*********************************************************************
     * Expr - arithmetic and comparison
     *
     * Expr ::= Expr + Expr
     *        | Expr - Expr
     *        | Expr * Expr
     *        | Expr / Expr
     *        | ~ Expr
     *        | Expr < Expr
     *        | Expr <= Expr
     *        | Expr = Expr
     *        | not Expr
     *        | (Expr)
     *********************************************************************/
    expr
    : expr '+' expr
    { @$ = @3; SET_NODELOC(@3); $$ = plus($1,$3); }
    | expr '-' expr
    { @$ = @3; SET_NODELOC(@3); $$ = sub($1,$3); }
    | expr '*' expr
    { @$ = @3; SET_NODELOC(@3); $$ = mul($1,$3); }
    | expr '/' expr
    { @$ = @3; SET_NODELOC(@3); $$ = divide($1,$3); }
    | '~' expr
    { @$ = @2; SET_NODELOC(@2); $$ = neg($2); }
    | expr '<' expr
    { @$ = @3; SET_NODELOC(@3); $$ = lt($1,$3); }
    | expr '=' expr
    { @$ = @3; SET_NODELOC(@3); $$ = eq($1,$3); }
    | expr LE expr
    { @$ = @3; SET_NODELOC(@3); $$ = leq($1,$3); }
    | NOT expr
    { @$ = @2; SET_NODELOC(@2); $$ = comp($2); }
    | '(' expr ')'
    { @$ = @3; SET_NODELOC(@3); $$ = $2; }
    ;

    /*********************************************************************
     * Expr - constants
     *
     * Expr ::= integer
     *        | string
     *        | true
     *        | false
     *********************************************************************/
    expr    /* constants */
    : INT_CONST
    { $$ = int_const($1); }
    | BOOL_CONST
    { $$ = bool_const($1); }
    | STR_CONST
    { $$ = string_const($1); }
    ;

    /*********************************************************************
     * Expr - identifier
     *
     * Expr ::= ID
     *********************************************************************/
    expr
    : OBJECTID
    { $$ = object($1); }
    ;

    /* end of grammar */
    %%

    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;

      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;

      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
