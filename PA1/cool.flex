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
 * comment_level: number of nested comments
 * string_contains_null: true if the current string contains a null
 */
int comment_level = 0;
int string_contains_null = 0;
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

PUNCTUATION     {LPAREN}|{RPAREN}|{LBRACE}|{RBRACE}|{COLON}|{COMMA}|{SEMICOLON}

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

ARITHMETIC_OP   {PLUS}|{SUB}|{MUL}|{DIV}|{NEG}
RELATIONAL_OP   {EQ}|{LT}|{DOT}|{AT}

/* Keywords Tokens */

CLASS       (?i:class)
INHERITS    (?i:inherits)

IF          (?i:if)
THEN        (?i:then)
ELSE        (?i:else)
FI          (?i:fi)
WHILE       (?i:while)
LOOP        (?i:loop)
POOL        (?i:pool)
IN          (?i:in)
OF          (?i:of)
CASE        (?i:case)
ESAC        (?i:esac)


LET         (?i:let)
NEW         (?i:new)
ISVOID      (?i:isvoid)
NOT         (?i:not)

TRUE        "t"(?i:rue)
FALSE       "f"(?i:alse)

/* Identifiers Tokens */

INT_CONST   [0-9]+
OBJECTID    [a-z][a-zA-Z0-9_]*|"self"
TYPEID      [A-Z][a-zA-Z0-9_]*|"SELF_TYPE"

/* white space */

WHITE_SPACE [\ \r\f\t\v]


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
{DARROW} {return (DARROW);}
{LE} {return (LE);}

 /*********************************************************************
  * The single-character operators.
  *********************************************************************/

{PUNCTUATION} {return yytext[0];}
{ARITHMETIC_OP} {return yytext[0];}
{RELATIONAL_OP} {return yytext[0];}

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
{NOT} {return (NOT);}
{NEW} {return (NEW);}
{ISVOID} {return (ISVOID);}

{TRUE} {
    cool_yylval.boolean = true;
    return (BOOL_CONST);
}

{FALSE} {
    cool_yylval.boolean = false;
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




 /*********************************************************************
  * String constants (C syntax)
  * Escape sequence \c is accepted for all characters c. Except for
  * \n \t \b \f, the result is c.
  *********************************************************************/

<INITIAL>\" {
    string_buf_ptr = string_buf;
    string_contains_null = false;
    BEGIN(STRING);
}

<STRING>\" {
    if(string_contains_null == false) {
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
    string_contains_null = true;
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
    string_contains_null = true;
}

<STRING><<EOF>> {
    cool_yylval.error_msg = ("EOF in string constant");
    BEGIN(INITIAL);
    return (ERROR);
}

<STRING>. { *string_buf_ptr++ = yytext[0]; }

 /*********************************************************************
  * Everything Else
  *********************************************************************/
{WHITE_SPACE}+    {}

<<EOF>> {yyterminate();}

. {
    cool_yylval.error_msg = yytext;
    return (ERROR);
}

%%
