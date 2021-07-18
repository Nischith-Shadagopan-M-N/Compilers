%union {
    struct node* snod;
}

%token ID INTCONST FLOATCONST 
%token PRINTF FRMT_SPEC
%token OROP ANDOP EQOP NEQOP GEQOP COMOP LEQOP POIOP DECOP INCOP SIZEOF 
%token BREAK CASE CONTINUE DEFAULT DO ELSE EXTERN FLOAT IF INT RETURN STRUCT SWITCH VOID WHILE
%token LBRACKET RBRACKET LBRACES RBRACES LCURLY RCURLY DOT AND STAR ADD SUB NOT DIV MOD LESSER GREATER SEMICOLON EQUAL COMMA COLON

%type <snod> program decl_list decl struct_decl var_decl type_spec extern_spec func_decl params param_list param stmt_list stmt while_stmt dowhile_stmt print_stmt format_specifier compound_stmt local_decls local_decl if_stmt return_stmt break_stmt continue_stmt switch_stmt compound_case single_case default_case assign_stmt incr_stmt decr_stmt expr Pexpr arg_list args integerLit floatLit identifier

%{
	#include <stdio.h> 
    #include <stdlib.h> 
    #include <string.h>

    #define TEXT(a) #a

	void yyerror(char *);
	int yylex(void);
	char mytext[100];
    int syntax = 0;
    extern char *yytext;
    long long int astlp = 0;
    long long int iflp = 0;
    long long int whilelp = 0;
    long long int switchlp = 0;
    long long int mainlp = 0;
    
    enum ntype{
        program,
        decl_list,
        decl,
        struct_decl,
        var_decl,
        type_spec,
        extern_spec,
        func_decl,
        params,
        param_list,
        param,
        stmt_list,
        stmt,
        expr_stmt,
        while_stmt,
        dowhile_stmt,
        print_stmt,
        format_specifier,
        compound_stmt,
        local_decls,
        local_decl,
        if_stmt,
        return_stmt,
        break_stmt,
        continue_stmt,
        switch_stmt,
        compound_case,
        single_case,
        default_case,
        assign_stmt,
        incr_stmt,
        decr_stmt,
        expr,
        Pexpr,
        arg_list,
        args,
        integerLit,
        floatLit,
        identifier,
        lcurly,
        rcurly,
        semicolon,
        comma,
        lbracket,
        rbracket,
        dot,
        lbraces,
        rbraces,
        star,
        equal,
        colon,
        greater,
        lesser,
        add,
        sub,
        Div,
        mod,
        not,
        and,
        id,
        intconst,
        floatconst, 
        Printf, 
        frmt_spec,
        orop, 
        andop, 
        eqop, 
        neqop, 
        geqop, 
        comop, 
        leqop, 
        poiop, 
        decop, 
        incop, 
        Sizeof, 
        Break, 
        Case, 
        Continue, 
        Default, 
        Do, 
        Else, 
        Extern, 
        Float, 
        If, 
        Int, 
        Return, 
        Struct, 
        Switch, 
        Void, 
        While,
        epsilon
    };

    const char* typename[] = {"program", "decl_list", "decl", "struct_decl", "var_decl", "type_spec", "extern_spec", "func_decl", "params", "param_list", "param", "stmt_list", "stmt", "expr_stmt", "while_stmt", "dowhile_stmt", "print_stmt", "format_specifier", "compound_stmt", "local_decls", "local_decl", "if_stmt", "return_stmt", "break_stmt", "continue_stmt", "switch_stmt", "compound_case", "single_case", "default_case", "assign_stmt", "incr_stmt", "decr_stmt", "expr", "Pexpr", "arg_list", "args", "integerLit", "floatLit", "identifier", "lcurly", "rcurly", "semicolon", "comma", "lbracket", "rbracket", "dot", "lbraces", "rbraces", "star", "equal", "colon", "greater", "lesser", "add", "sub", "Div", "mod", "not", "and", "id", "intconst", "floatconst", "Printf", "frmt_spec", "orop", "andop", "eqop", "neqop", "geqop", "comop", "leqop", "poiop", "decop", "incop", "Sizeof", "Break", "Case", "Continue", "Default", "Do", "Else", "Extern", "Float", "If", "Int", "Return", "Struct", "Switch", "Void", "While", "epsilon"};

    struct node{
        enum ntype nt;
        struct node* children[9];
        char str[100];
        long long int height;
        long long int lp;
    };

    long long int max(long long int num1, long long int num2){
        return (num1 > num2 ) ? num1 : num2;
    }

    struct node* cons_lexstr(enum ntype a, char sr[]){
        //printf("malloc1\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        strcpy(newnode->str, sr);
        newnode->height = 1;
        newnode->lp = 1;
        //printf("%s, %lld\n", typename[a], newnode->height);
        return newnode;
    }

    struct node* cons_lex(enum ntype a){
        //printf("malloc2\n");
        struct node* newnode = (struct node*) malloc(sizeof(struct node));
        newnode->nt = a;
        for(int i=0; i<9;i++){
            newnode->children[i] = NULL;
        }
        newnode->height = 1;
        newnode->lp = 1;
        //printf("%s, %lld\n", typename[a], newnode->height);
        return newnode;
    }

    struct node* cons_rep(enum ntype typ, int c, struct node* nodarr[]){
        //printf("malloc3\n");
        struct node* nod = (struct node*) malloc(sizeof(struct node));
        nod->nt = typ;
        //printf("malloc4\n");
        for(int i=0; i<c; i++){
            nod->children[i] = nodarr[i];
        }
        long long int maxlp = 0;
        long long int maxh = 0;
        long long int smaxh = 0;
        for(int i=0; i<c; i++){
            maxlp = max(maxlp, nodarr[i]->lp);
            if((nodarr[i]->height)>maxh){
                smaxh = maxh;
                maxh = (nodarr[i]->height);
            }
            else{
                if((nodarr[i]->height)>smaxh){
                    smaxh = (nodarr[i]->height);
                }
            }
        }
        nod->height = maxh + 1;
        nod->lp = max(maxlp, maxh+smaxh+1);
        //printf("%s, %lld\n", typename[typ], nod->height);
        if(typ==program){
            astlp = nod->lp;
        }
        if(typ==if_stmt){
            iflp = max(iflp, nod->lp);
        }
        if(typ==while_stmt){
            whilelp = max(whilelp, nod->lp);
        }
        if(typ==switch_stmt){
            switchlp = max(switchlp, nod->lp);
        }
        if(typ==func_decl && (strcmp(nodarr[1]->children[0]->str, "main")==0)){
            mainlp = max(mainlp, nod->lp);
        }
        return nod;
    }

%}

%%

program
    : decl_list {$$ = cons_rep(program, 1, (struct node*[]){$1});}
    ; 

decl_list
    : decl_list decl    {$$ = cons_rep(decl_list, 2, (struct node*[]){$1, $2});}
    | decl  {$$ = cons_rep(decl_list, 1, (struct node*[]){$1});}
    ;

decl
    : var_decl  {$$ = cons_rep(decl, 1, (struct node*[]){$1});} 
    | func_decl {$$ = cons_rep(decl, 1, (struct node*[]){$1});}
    | struct_decl   {$$ = cons_rep(decl, 1, (struct node*[]){$1});}
    ;

struct_decl
    : STRUCT identifier LCURLY local_decls RCURLY SEMICOLON  {$$ = cons_rep(struct_decl, 6, (struct node*[]){cons_lex(Struct), $2, cons_lex(lcurly), $4, cons_lex(rcurly), cons_lex(semicolon)});}
    ;

var_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(var_decl, 3, (struct node*[]){$1, $2, cons_lex(semicolon)});}
    | type_spec identifier COMMA var_decl   {$$ = cons_rep(var_decl, 4, (struct node*[]){$1, $2, cons_lex(comma), $4});}
    | type_spec identifier LBRACKET integerLit RBRACKET SEMICOLON   {$$ = cons_rep(var_decl, 6, (struct node*[]){$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    | type_spec identifier LBRACKET integerLit RBRACKET COMMA var_decl  {$$ = cons_rep(var_decl, 7, (struct node*[]){$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(comma), $7});}
    ;

type_spec
    : extern_spec VOID {$$ = cons_rep(type_spec, 2, (struct node*[]){$1, cons_lex(Void)});}
    | extern_spec INT   {$$ = cons_rep(type_spec, 2, (struct node*[]){$1, cons_lex(Int)});}
    | extern_spec FLOAT {$$ = cons_rep(type_spec, 2, (struct node*[]){$1, cons_lex(Float)});}
    | extern_spec VOID STAR {$$ = cons_rep(type_spec, 3, (struct node*[]){$1, cons_lex(Void), cons_lex(star)});}
    | extern_spec INT STAR  {$$ = cons_rep(type_spec, 3, (struct node*[]){$1, cons_lex(Int), cons_lex(star)});}
    | extern_spec FLOAT STAR    {$$ = cons_rep(type_spec, 3, (struct node*[]){$1, cons_lex(Float), cons_lex(star)});}
    | STRUCT identifier {$$ = cons_rep(type_spec, 2, (struct node*[]){cons_lex(Struct), $2});}  
    | STRUCT identifier STAR    {$$ = cons_rep(type_spec, 3, (struct node*[]){cons_lex(Struct), $2, cons_lex(star)});}
    ;   

extern_spec
    : EXTERN    {$$ = cons_rep(extern_spec, 1, (struct node*[]){cons_lex(Extern)});}
    | /*empty*/ {$$ = cons_rep(extern_spec, 1, (struct node*[]){cons_lex(epsilon)});}
    ;

func_decl
    : type_spec identifier LBRACES params RBRACES compound_stmt {$$ = cons_rep(func_decl, 6, (struct node*[]){$1, $2, cons_lex(lbraces), $4, cons_lex(rbraces), $6});}
    ;

params
    : param_list    {$$ = cons_rep(params, 1, (struct node*[]){$1});}
    | /*empty*/ {$$ = cons_rep(params, 1, (struct node*[]){cons_lex(epsilon)});}
    ;

param_list
    : param_list COMMA param    {$$ = cons_rep(param_list, 3, (struct node*[]){$1, cons_lex(comma), $3});}
    | param {$$ = cons_rep(param_list, 1, (struct node*[]){$1});}
    ;

param
    : type_spec identifier  {$$ = cons_rep(param, 2, (struct node*[]){$1, $2});}
    | type_spec identifier LBRACKET RBRACKET    {$$ = cons_rep(param, 4, (struct node*[]){$1, $2, cons_lex(lbracket), cons_lex(rbracket)});}
    ;

stmt_list
    : stmt_list stmt   {$$ = cons_rep(stmt_list, 2, (struct node*[]){$1, $2});}
    | stmt  {$$ = cons_rep(stmt_list, 1, (struct node*[]){$1});}
    ;

stmt
    : assign_stmt   {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | compound_stmt {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | if_stmt   {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | while_stmt    {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | switch_stmt   {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | return_stmt   {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | break_stmt    {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | continue_stmt {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | dowhile_stmt  {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | print_stmt    {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | incr_stmt {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    | decr_stmt {$$ = cons_rep(stmt, 1, (struct node*[]){$1});}
    ;

while_stmt
    : WHILE LBRACES expr RBRACES stmt   {$$ = cons_rep(while_stmt, 5, (struct node*[]){cons_lex(While), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    ;

dowhile_stmt
    : DO stmt WHILE LBRACES expr RBRACES SEMICOLON  {$$ = cons_rep(dowhile_stmt, 7, (struct node*[]){cons_lex(Do), $2, cons_lex(While), cons_lex(lbraces), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

print_stmt
    : PRINTF LBRACES format_specifier COMMA identifier RBRACES SEMICOLON    {$$ = cons_rep(print_stmt, 7, (struct node*[]){cons_lex(Printf), cons_lex(lbraces), $3, cons_lex(comma), $5, cons_lex(rbraces), cons_lex(semicolon)});}
    ;

format_specifier
    : FRMT_SPEC {$$ = cons_rep(format_specifier, 1, (struct node*[]){cons_lex(frmt_spec)});}
    ;

compound_stmt  
    : LCURLY local_decls stmt_list RCURLY   {$$ = cons_rep(compound_stmt, 4, (struct node*[]){cons_lex(lcurly), $2, $3, cons_lex(rcurly)});}
    ;

local_decls
    : local_decls local_decl  {$$ = cons_rep(local_decls, 2, (struct node*[]){$1, $2});}
    | /*empty*/ {$$ = cons_rep(local_decls, 1, (struct node*[]){cons_lex(epsilon)});}
    ;

local_decl
    : type_spec identifier SEMICOLON    {$$ = cons_rep(local_decl, 3, (struct node*[]){$1, $2, cons_lex(semicolon)});}
    | type_spec identifier LBRACKET expr RBRACKET SEMICOLON {$$ = cons_rep(local_decl, 6, (struct node*[]){$1, $2, cons_lex(lbracket), $4, cons_lex(rbracket), cons_lex(semicolon)});}
    ;

if_stmt
    : IF LBRACES expr RBRACES stmt  {$$ = cons_rep(if_stmt, 5, (struct node*[]){cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5});}
    | IF LBRACES expr RBRACES stmt ELSE stmt    {$$ = cons_rep(if_stmt, 7, (struct node*[]){cons_lex(If), cons_lex(lbraces), $3, cons_lex(rbraces), $5, cons_lex(Else), $7});}
    ;

return_stmt
    : RETURN SEMICOLON  {$$ = cons_rep(return_stmt, 2, (struct node*[]){cons_lex(Return), cons_lex(semicolon)});}
    | RETURN expr SEMICOLON {$$ = cons_rep(return_stmt, 3, (struct node*[]){cons_lex(Return), $2, cons_lex(semicolon)});}
    ;

break_stmt
    : BREAK SEMICOLON   {$$ = cons_rep(break_stmt, 2, (struct node*[]){cons_lex(Break), cons_lex(semicolon)});}
    ;

continue_stmt
    : CONTINUE SEMICOLON    {$$ = cons_rep(continue_stmt, 2, (struct node*[]){cons_lex(Continue), cons_lex(semicolon)});}
    ;

switch_stmt
    : SWITCH LBRACES expr RBRACES LCURLY compound_case default_case RCURLY  {$$ = cons_rep(switch_stmt, 8, (struct node*[]){cons_lex(Switch), cons_lex(lbraces), $3, cons_lex(rbraces), cons_lex(lcurly), $6, $7, cons_lex(rcurly)});}
    ;

compound_case 
    : single_case compound_case {$$ = cons_rep(compound_case, 2, (struct node*[]){$1, $2});}
    | single_case   {$$ = cons_rep(compound_case, 1, (struct node*[]){$1});}
    ;

single_case
    : CASE integerLit COLON stmt_list   {$$ = cons_rep(single_case, 4, (struct node*[]){cons_lex(Case), $2, cons_lex(colon), $4});}
    ;

default_case
    : DEFAULT COLON stmt_list   {$$ = cons_rep(default_case, 3, (struct node*[]){cons_lex(Default), cons_lex(colon), $3});}
    ;

assign_stmt
    : identifier EQUAL expr SEMICOLON   {$$ = cons_rep(assign_stmt, 2, (struct node*[]){cons_rep(equal, 2, (struct node*[]){$1, $3}), cons_lex(semicolon)});}
    | identifier LBRACKET expr RBRACKET EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, (struct node*[]){cons_rep(equal, 5, (struct node*[]){$1, cons_lex(lbracket), $3, cons_lex(rbracket), $6}), cons_lex(semicolon)});}
    | identifier POIOP identifier EQUAL expr SEMICOLON  {$$ = cons_rep(assign_stmt, 2, (struct node*[]){cons_rep(equal, 4, (struct node*[]){$1, cons_lex(poiop), $3, $5}), cons_lex(semicolon)});}
    | identifier DOT identifier EQUAL expr SEMICOLON    {$$ = cons_rep(assign_stmt, 2, (struct node*[]){cons_rep(equal, 4, (struct node*[]){$1, cons_lex(dot), $3, $5}), cons_lex(semicolon)});}
    ;

incr_stmt
    : identifier INCOP SEMICOLON    {$$ = cons_rep(incr_stmt, 3, (struct node*[]){$1, cons_lex(incop), cons_lex(semicolon)});}
    ;

decr_stmt
    : identifier DECOP SEMICOLON    {$$ = cons_rep(decr_stmt, 3, (struct node*[]){$1, cons_lex(decop), cons_lex(semicolon)});}
    ;

expr
    : Pexpr LESSER Pexpr    {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(lesser, 2, (struct node*[]){$1, $3})});}
    | Pexpr GREATER Pexpr   {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(greater, 2, (struct node*[]){$1, $3})});}
    | Pexpr LEQOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(leqop, 2, (struct node*[]){$1, $3})});}
    | Pexpr GEQOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(geqop, 2, (struct node*[]){$1, $3})});}
    | Pexpr OROP Pexpr  {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(orop, 2, (struct node*[]){$1, $3})});}
    | SIZEOF LBRACES Pexpr RBRACES  {$$ = cons_rep(expr, 4, (struct node*[]){cons_lex(Sizeof), cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | Pexpr EQOP Pexpr  {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(eqop, 2, (struct node*[]){$1, $3})});}
    | Pexpr NEQOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(neqop, 2, (struct node*[]){$1, $3})});}
    | Pexpr COMOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(comop, 2, (struct node*[]){$1, $3})});}
    | Pexpr ANDOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(andop, 2, (struct node*[]){$1, $3})});}
    | Pexpr POIOP Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(poiop, 2, (struct node*[]){$1, $3})});}
    | Pexpr ADD Pexpr   {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(add, 2, (struct node*[]){$1, $3})});}
    | Pexpr SUB Pexpr   {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(sub, 2, (struct node*[]){$1, $3})});}
    | Pexpr STAR Pexpr  {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(star, 2, (struct node*[]){$1, $3})});}
    | Pexpr DIV Pexpr   {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(Div, 2, (struct node*[]){$1, $3})});}
    | Pexpr MOD Pexpr   {$$ = cons_rep(expr, 1, (struct node*[]){cons_rep(mod, 2, (struct node*[]){$1, $3})});}
    | NOT Pexpr {$$ = cons_rep(expr, 2, (struct node*[]){cons_lex(not), $2});}
    | SUB Pexpr {$$ = cons_rep(expr, 2, (struct node*[]){cons_lex(sub), $2});}
    | ADD Pexpr {$$ = cons_rep(expr, 2, (struct node*[]){cons_lex(add), $2});}
    | STAR Pexpr    {$$ = cons_rep(expr, 2, (struct node*[]){cons_lex(star), $2});}
    | AND Pexpr {$$ = cons_rep(expr, 2, (struct node*[]){cons_lex(and), $2});}
    | Pexpr {$$ = cons_rep(expr, 1, (struct node*[]){$1});}
    | identifier LBRACES args RBRACES   {$$ = cons_rep(expr, 4, (struct node*[]){$1, cons_lex(lbraces), $3, cons_lex(rbraces)});}
    | identifier LBRACKET expr RBRACKET {$$ = cons_rep(expr, 4, (struct node*[]){$1, cons_lex(lbracket), $3, cons_lex(rbracket)});}
    ;

Pexpr
    : integerLit    {$$ = cons_rep(Pexpr, 1, (struct node*[]){$1});}
    | floatLit  {$$ = cons_rep(Pexpr, 1, (struct node*[]){$1});}
    | identifier    {$$ = cons_rep(Pexpr, 1, (struct node*[]){$1});}
    | LBRACES expr RBRACES  {$$ = cons_rep(Pexpr, 3, (struct node*[]){cons_lex(lbraces), $2, cons_lex(rbraces)});}
    ;

arg_list
    : arg_list COMMA expr  {$$ = cons_rep(arg_list, 3, (struct node*[]){$1, cons_lex(comma), $3});}
    | expr  {$$ = cons_rep(arg_list, 1, (struct node*[]){$1});}
    ;

args 
    : arg_list  {$$ = cons_rep(args, 1, (struct node*[]){$1});}
    | /*empty*/ {$$ = cons_rep(args, 1, (struct node*[]){cons_lex(epsilon)});}
    ;

integerLit
    : INTCONST  {$$ = cons_rep(integerLit, 1, (struct node*[]){cons_lexstr(intconst, yytext)});}
    ;

floatLit
    : FLOATCONST    {$$ = cons_rep(floatLit, 1, (struct node*[]){cons_lexstr(floatconst, yytext)});}
    ;

identifier
    : ID    {$$ = cons_rep(identifier, 1, (struct node*[]){cons_lexstr(id, yytext)});}
    ;

%%

extern FILE *yyin;

void yyerror(char *s) {
    syntax = 1;
}

int main() {
    yyparse();
    
    if(syntax!=0){
        printf("syntax error\n");
        return 0;
    }
    printf("%lld\n", astlp);
    printf("%lld\n", iflp);
    printf("%lld\n", whilelp);
    printf("%lld\n", switchlp);
    printf("%lld\n", mainlp);
    return 0;
}