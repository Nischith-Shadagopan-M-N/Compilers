%token ID INTCONST FLOATCONST CHARCONST STRING 
%token OROP ANDOP EQOP NEQOP GEQOP COMOP LEQOP POIOP DECOP INCOP SIZEOF 
%token BREAK CASE CHAR CONTINUE DEFAULT DO DOUBLE ELSE EXTERN FLOAT FOR IF INT LONG RETURN SHORT STRUCT SWITCH VOID WHILE

%left ';'
%left ','
%right '='
%left OROP
%left ANDOP
%left '|'
%left '^'
%left '&'
%left EQOP NEQOP
%left '<' LEQOP '>' GEQOP COMOP
%left '+' '-'
%left '*' '/' '%'
%right CAST
%right UNAOP
%left '('')' '[' ']' POIOP '.' DECOP INCOP
%{
	#include <stdio.h>
	void yyerror(char *);
	int yylex(void);
	char mytext[100];
    int gd = 0;
    int fd = 0;
    int ic = 0;
    int pd = 0;
    int iwe = 0;
    int iemd = 0;
    int iemdtemp = 0;
    int syntax = 0;
%}

%%

PROGRAM:
    FUNCDEF {gd++;fd++;}
    |DECLARATION    {gd++;}
    |PROGRAM FUNCDEF    {gd++;fd++;}
    |PROGRAM DECLARATION    {gd++;}
;

CONST:   
    INTCONST    {ic++;}
    |FLOATCONST
    |CHARCONST  {ic++;}
;

EXP1:
    CONST   
    |ID     
    |STRING 
    |'(' EXPR ')'
    |EXP1 '.' ID
    |EXP1 '[' EXPR ']'
    |EXP1 '(' ')'
    |EXP1 '(' EXPR ')'
    |EXP1 POIOP ID
    |EXP1 INCOP  
    |EXP1 DECOP 
    |'(' TYPE ')' '{' INITLINES '}' %prec UNAOP
    |'(' TYPE ')' '{' INITLINES ',' '}' %prec UNAOP
    |INCOP  EXP1     %prec UNAOP
    |DECOP  EXP1     %prec UNAOP
    |'&' EXP1    %prec UNAOP
    |'*' EXP1    %prec UNAOP
    |'+' EXP1    %prec UNAOP    
    |'-' EXP1    %prec UNAOP
    |'~' EXP1    %prec UNAOP
    |'!' EXP1    %prec UNAOP
    |SIZEOF EXP1    %prec UNAOP
    |SIZEOF '(' TYPE ')'    %prec UNAOP 
    |'(' TYPE ')' EXP1   %prec CAST
;

EXP:
    EXP1
    |EXP '|' EXP
    |EXP '^' EXP
    |EXP '&' EXP
    |EXP '<' EXP
    |EXP '>' EXP
    |EXP '+' EXP
    |EXP '-' EXP
    |EXP '*' EXP
    |EXP '/' EXP
    |EXP '%' EXP
    |EXP OROP EXP
    |EXP ANDOP EXP
    |EXP EQOP EXP
    |EXP NEQOP EXP
    |EXP LEQOP EXP
    |EXP GEQOP EXP
    |EXP COMOP EXP
;

ASS:
    EXP
    |EXP1 '=' ASS 
;

EXPR:
    ASS
    |ASS ',' ASS
;

TYPE1:
    VOID
    |CHAR
    |SHORT
    |INT
    |LONG
    |FLOAT
    |DOUBLE
    |VOID TYPE1
    |CHAR TYPE1
    |SHORT TYPE1
    |INT TYPE1
    |LONG TYPE1
    |FLOAT TYPE1
    |DOUBLE TYPE1
    |STRUCTURE
    |STRUCTURE TYPE1
;

TYPE2:
    EXTERN
    |EXTERN TYPE2
    |VOID
    |CHAR
    |SHORT
    |INT
    |LONG
    |FLOAT
    |DOUBLE
    |VOID TYPE2
    |CHAR TYPE2
    |SHORT TYPE2
    |INT TYPE2
    |LONG TYPE2
    |FLOAT TYPE2
    |DOUBLE TYPE2
    |STRUCTURE
    |STRUCTURE TYPE2
;    

POINTER:
    '*'
    |'*' POINTER
;

STRUCTURE:
    STRUCT '{' STRUCDECLINES ';' '}'
    |STRUCT ID '{' STRUCDECLINES ';' '}'
    |STRUCT ID
;

STRUCDECLINES:
    TYPE1
    |TYPE1 VARLINES
    |STRUCDECLINES ';' STRUCDECLINES
;

VARLINES:
    ':' EXP
    |POINTER VAR ':' EXP    {pd++;}
    |VAR ':' EXP
    |POINTER VAR    {pd++;}
    |VAR
    |VARLINES ',' VARLINES
;

VAR:
    ID
    |'(' VAR ')'
    |VAR '[' ']'
    |VAR '[' '*' ']'
    |VAR '[' ASS ']'
    |VAR '(' PARAMLINES ')'
    |VAR '(' ')'
    |VAR '(' IDLINES ')'
;

VAR1:
    '(' VAR1 ')'
    |VAR1 '[' ']'
    |VAR1 '[' '*' ']'
    |VAR1 '[' ASS ']'
    |VAR1 '(' ')'
    |VAR1 '(' PARAMLINES ')'
    |'[' ']'
    |'[' '*' ']'
    |'[' ASS ']'
    |'(' ')'
    |'(' PARAMLINES ')'
;

TYPE:
    TYPE1 POINTER VAR1  
    |TYPE1 VAR1
    |TYPE1 POINTER
    |TYPE1
;

IDLINES:
    ID
    |IDLINES ',' IDLINES
;

PARAMLINES:
    TYPE2 POINTER VAR   {pd++;}
    |TYPE2 VAR
    |TYPE2 POINTER VAR1
    |TYPE2 VAR1
    |TYPE2 POINTER
    |TYPE2
    |PARAMLINES ',' PARAMLINES
;

INITLINES:
    ATT '=' '{' INITLINES '}'
    |ATT '=' '{' INITLINES ',' '}'
    |ATT '=' ASS
    |'{' INITLINES '}'
    |'{' INITLINES ',' '}'
    |ASS
    |INITLINES ',' INITLINES
;

ATT:
    '[' ASS ']'
    |'.' ID
    |ATT '[' ASS ']'
    |ATT '.' ID
;

INITDECLINES:
    POINTER VAR '=' '{' INITLINES '}'   {pd++;}
    |POINTER VAR '=' '{' INITLINES ',' '}'  {pd++;}
    |POINTER VAR '=' ASS    {pd++;}
    |VAR '=' '{' INITLINES '}'
    |VAR '=' '{' INITLINES ',' '}'
    |VAR '=' ASS
    |POINTER VAR    {pd++;}
    |VAR
    |INITDECLINES ',' INITDECLINES
;

DECLARATION:
    TYPE2 ';'
    |TYPE2 INITDECLINES ';'
;

STATEMENT:
    LABEL
    |'{' '}'
    |'{' LINES '}'
    |';'
    |EXPR ';'
    |SELECTION
    |ITERATION
    |JUMP
;

LINES:
    DECLARATION
    |STATEMENT
    |LINES DECLARATION
    |LINES STATEMENT
;

LABEL:
    ID ':' STATEMENT
    |CASE EXP ':' STATEMENT
    |DEFAULT ':' STATEMENT
;

SELECTION:
    IF '(' EXPR ')' STATEMENT ELSE {iemdtemp++;if(iemdtemp>iemd){iemd=iemdtemp;};} STATEMENT {iemdtemp--;if(iemdtemp>iemd){iemd=iemdtemp;};}
    |IF '(' EXPR ')' STATEMENT  {iwe++;}
    |SWITCH '(' EXPR ')' STATEMENT
;

EXPRSTMT:
    ';'
    |EXPR ';'
;

ITERATION:
    WHILE '(' EXPR ')' STATEMENT
    |DO STATEMENT WHILE '(' EXPR ')' ';'
    |FOR '(' EXPRSTMT EXPRSTMT ')' STATEMENT
    |FOR '(' EXPRSTMT EXPRSTMT EXPR ')' STATEMENT
    |FOR '(' DECLARATION EXPRSTMT ')' STATEMENT
    |FOR '(' DECLARATION EXPRSTMT EXPR ')' STATEMENT
;

JUMP:
    CONTINUE ';'
    |BREAK ';'
    |RETURN ';'
    |RETURN EXPR ';'
;

DECLINES:
    DECLARATION
    |DECLINES DECLARATION
;

FUNCDEF:
    TYPE2 POINTER VAR DECLINES '{' '}'  {pd++;}
    |TYPE2 POINTER VAR DECLINES '{' LINES '}'   {pd++;}
    |TYPE2 VAR DECLINES '{' '}'
    |TYPE2 VAR DECLINES '{' LINES '}'
    |TYPE2 POINTER VAR '{' '}'  {pd++;}
    |TYPE2 POINTER VAR '{' LINES '}'    {pd++;}
    |TYPE2 VAR '{' '}'  
    |TYPE2 VAR '{' LINES '}'
;

%%

extern FILE *yyin;

void yyerror(char *s) {
    syntax = 1;
}

int main(int argc, char* argv[]) {
    if ( argc !=2) {
        printf("***process terminated*** [input error]: invalid number of command-line arguments\n");
        return 0;
    }   
    FILE *fp = fopen( argv[1] , "r" );
    if (!fp) {
        printf("***process terminated*** [input error]: no such file %s exists\n" , argv[1] );
        return 0;
    } 
    yyin = fp;
    do {
        yyparse();
    } while (!feof(yyin));
    
    if(syntax!=0){
        printf("***parsing terminated*** [syntax error]\n");
        return 0;
    }

    printf("***parsing successful***\n");
    printf("#global_declarations = %d\n", gd);
    printf("#function_definitions = %d\n", fd);
    printf("#integer_constants = %d\n", ic);
    printf("#pointers_declarations = %d\n", pd);
    printf("#ifs_without_else = %d\n", iwe);
    printf("if-else max-depth = %d\n", iemd);

    return 0;
}