/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
    if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
        YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int comment_level = 0;
int error_flag = 0;
%}

/*********************************************************************
 * Define names for regular expressions here.
 *********************************************************************/

/* Punctuation */
LPAREN          "("
RPAREN          ")"
LBRACE          "{"
RBRACE          "}"
COLON           ":"
COMMA           ","
SEMICOLON       ";"

/* Operators Tokens */

ASSIGN          "<-"
PLUS            "+"
SUB             "-"
MUL             "*"
DIV             "/"
NEG             "~"
EQ              "="
LT              "<"
LE              "<="
DOT             "."
AT              "@"
DARROW          "=>"

OPERATORS_SINGLE    {PLUS}|{SUB}|{MUL}|{DIV}|{NEG}|{EQ}|{LT}|{DOT}|{AT}|{LPAREN}|{RPAREN}|{LBRACE}|{RBRACE}|{COLON}|{COMMA}|{SEMICOLON}

/* Keywords Tokens */

CLASS       {C}{L}{A}{S}{S}
INHERITS    {I}{N}{H}{E}{R}{I}{T}{S}

IF          {I}{F}
THEN        {T}{H}{E}{N}
ELSE        {E}{L}{S}{E}
FI          {F}{I}
WHILE       {W}{H}{I}{L}{E}
LOOP        {L}{O}{O}{P}
POOL        {P}{O}{O}{L}
IN          {I}{N}
OF          {O}{F}
CASE        {C}{A}{S}{E}
ESAC        {E}{S}{A}{C}


LET         {L}{E}{T}
NEW         {N}{E}{W}
ISVOID      {I}{S}{V}{O}{I}{D}
NOT         {N}{O}{T}

TRUE        "t"{R}{U}{E}
FALSE       "f"{A}{L}{S}{E}

/* Identifiers Tokens */

INT_CONST   [0-9]+
OBJECTID    [a-z][a-zA-Z0-9_]*|"self"
TYPEID      [A-Z][a-zA-Z0-9_]*|"SELF_TYPE"

/* white space */

WHITE_SPACE [\ \r\f\t\v]

/* internal tokens */

A           [aA]
B           [bB]
C           [cC]
D           [dD]
E           [eE]
F           [fF]
G           [gG]
H           [hH]
I           [iI]
J           [jJ]
K           [kK]
L           [lL]
M           [mM]
N           [nN]
O           [oO]
P           [pP]
Q           [qQ]
R           [rR]
S           [sS]
T           [tT]
U           [uU]
V           [vV]
W           [wW]
X           [xX]
Y           [yY]
Z           [zZ]


%x    COMMENT_ML COMMENT_L STRING
%%

 /*********************************************************************
  * Nested comments
  *********************************************************************/

<INITIAL,COMMENT_L>-- {
    BEGIN(COMMENT_L);
}

<COMMENT_L>"\n" {
    curr_lineno++;
    if(comment_level>0)
        BEGIN(COMMENT_ML);
    else
        BEGIN(INITIAL);
}

<INITIAL,COMMENT_ML>"(*" {
    comment_level++;
    BEGIN(COMMENT_ML);
}

<COMMENT_ML,INITIAL>"\n" {
    curr_lineno++;
}

<COMMENT_ML,INITIAL>"*)" {
    comment_level--;
    if (comment_level == 0)
        BEGIN(INITIAL);
    else if (comment_level < 0)
    {
        comment_level = 0;
        cool_yylval.error_msg = "Unmatched *)";
        return (ERROR);
    }
}

<COMMENT_ML><<EOF>>  {
    cool_yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return (ERROR);
}
<COMMENT_ML,COMMENT_L>. {}

 /*********************************************************************
  * The multiple-character operators.
  *********************************************************************/

{ASSIGN} {return (ASSIGN);}
{NOT} {return (NOT);}
{LE} {return (LE);}

 /*********************************************************************
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  *********************************************************************/

{CLASS} {return (CLASS);}
{ELSE} {return (ELSE);}
{FI} {return (FI);}
{IF} {return (IF);}
{IN} {return (IN);}
{INHERITS} {return (INHERITS);}
{LET} {return (LET);}
{LOOP} {return (LOOP);}
{POOL} {return (POOL);}
{THEN} {return (THEN);}
{WHILE} {return (WHILE);}
{CASE} {return (CASE);}
{ESAC} {return (ESAC);}
{OF} {return (OF);}
{DARROW} {return (DARROW);}
{NEW} {return (NEW);}
{ISVOID} {return (ISVOID);}

{TRUE} {
    cool_yylval.boolean = 1;
    return (BOOL_CONST);
}

{FALSE} {
    cool_yylval.boolean = 0;
    return (BOOL_CONST);
}

{TYPEID} {
    cool_yylval.symbol = idtable.add_string(yytext, yyleng);
    return (TYPEID);
}

{OBJECTID} {
    cool_yylval.symbol = idtable.add_string(yytext, yyleng);
    return (OBJECTID);
}

{INT_CONST} {
    cool_yylval.symbol = inttable.add_string(yytext,yyleng);
    return (INT_CONST);
}

{OPERATORS_SINGLE} {return yytext[0];}
{WHITE_SPACE}+    {}

 /*********************************************************************
  * String constants (C syntax)
  * Escape sequence \c is accepted for all characters c. Except for
  * \n \t \b \f, the result is c.
  *********************************************************************/

<INITIAL>\" {
    string_buf_ptr = string_buf;
    error_flag = 0;
    BEGIN(STRING);
}

<STRING>\" {
    if(error_flag == 0) {
         *string_buf_ptr = '\0';
         if(string_buf_ptr - string_buf + 1 > MAX_STR_CONST) {
              cool_yylval.error_msg = "String constant too long";
              BEGIN(INITIAL);
              return (ERROR);
              }
         else {
         cool_yylval.symbol = stringtable.add_string(string_buf,MAX_STR_CONST);
         BEGIN(INITIAL);
         return (STR_CONST);
         }
    }
    else {
        BEGIN(INITIAL);
        return (ERROR);
    }
}

<STRING>\\n { *string_buf_ptr++ = '\n'; }
<STRING>\\t { *string_buf_ptr++ = '\t'; }
<STRING>\\b { *string_buf_ptr++ = '\b'; }
<STRING>\\f { *string_buf_ptr++ = '\f'; }
<STRING>\\\\ { *string_buf_ptr++ = '\\'; }
<STRING>\\\0 {
    cool_yylval.error_msg = "String contains escaped null character.";
    error_flag = 1;
}

<STRING>\\\n {
    *string_buf_ptr++ = '\n';
    curr_lineno++;
}

<STRING>\\\"  { *string_buf_ptr++ = '\"'; }

<STRING>\n {
    curr_lineno++;
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(INITIAL);
    return (ERROR);
}

<STRING>\\. { *string_buf_ptr++ = yytext[1]; }

<STRING>\0 {
    cool_yylval.error_msg = "String contains null character.";
    error_flag = 1;
}

<STRING><<EOF>> {
    cool_yylval.error_msg = ("EOF in string constant");
    BEGIN(INITIAL);
    return (ERROR);
}

<STRING>. { *string_buf_ptr++ = yytext[0]; }

 /*********************************************************************
  * EOF 
  *********************************************************************/

<<EOF>> {yyterminate();}

. {
    cool_yylval.error_msg = yytext;
    return (ERROR);
}

%%
