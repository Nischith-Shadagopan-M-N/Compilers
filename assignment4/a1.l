%x	comm0	comm1

%{
	#include <stdlib.h>
	#include "y.tab.hpp"
	void yyerror(char *);
	long long int lineno = 1;
	extern char mytext[];
%}

letter	[a-zA-Z_] 
digit	[0-9]
intsuff	(([uU])([lL]|(ll|LL)))|(([lL]|(ll|LL))([uU]))
flosuff	[flFL]
hexdigit	[0-9a-fA-F]
exp	[eE](("+"|"-")?)([0-9]+)
binexp	[pP](("+"|"-")?)([0-9]+)
hexpre	(0x)
univpre	"\\"[uU] 

%%

printf return PRINTF;

scanf return SCANF;

break	return BREAK;

case	return CASE;

continue	return CONTINUE;

default	return DEFAULT;

do	return DO;

else	return ELSE;

extern	return EXTERN;

float	return FLOAT;

if	return IF;

int	return INT;

return	return RETURN;

sizeof	return SIZEOF;

struct	return STRUCT;

switch	return SWITCH;

void	return VOID;

while	return WHILE;

"\"\%"d"\\"n"\""	return FRMT_SPEC;

"\"\%"d"\""	return FRMT_SPEC;

"/""/".*	;

"/""*"	{BEGIN(comm0);}

<comm0>"*"	{BEGIN(comm1);}

<comm0>\n	{lineno++;}

<comm0>[^*\n]	;

<comm1>"*"		;

<comm1>"/"		{BEGIN(INITIAL);}

<comm1>[^*/]	{BEGIN(comm0);}

({letter}+)({letter}|{digit}|{univpre}{hexdigit}{hexdigit}{hexdigit}{hexdigit})*    return ID;

[1-9]{digit}*{intsuff}?   return INTCONST;

0[0-7]*{intsuff}?     return INTCONST;

{hexpre}{hexdigit}+{intsuff}?      return INTCONST;

({digit}+){exp}({flosuff}?)		return FLOATCONST;

({digit}+)"."({digit}*)({exp}?)({flosuff}?)	return FLOATCONST;

"."({digit}+)({exp}?)({flosuff}?)	return FLOATCONST;

{hexpre}({hexdigit}+)("."?)({hexdigit}*){binexp}({flosuff}?)	return FLOATCONST;

{hexpre}"."({hexdigit}+){binexp}({flosuff}?)	return FLOATCONST;

"\+""\+"	return INCOP;

"-""-"		return DECOP;

"-""\>"		return POIOP;

"\<""="		return LEQOP;

"\>""="		return GEQOP;

"\<""=""\>"		return COMOP;

"=""="		return EQOP;

"!""="		return NEQOP;

"&""&"		return ANDOP;

"\|""\|"	return OROP;

"\["		return LBRACKET;

"\]"		return RBRACKET;

"\("		return LBRACES;

"\)"		return RBRACES;

"\{"		return LCURLY;

"\}"		return RCURLY;

"\."		return DOT;

"&"		return AND;

"\*"		return STAR;

"\+"		return ADD;

"-"		return SUB;

"!"		return NOT;

"\/"		return DIV;

"\%"		return MOD;

"\<"		return LESSER;

"\>"		return GREATER;

";"		return SEMICOLON;

"="		return EQUAL;

","		return COMMA;

":"		return COLON;

[\n]	{lineno++;};

[ \t\v\f]	;

.	;

%%

int yywrap(void) {
	if(YY_START != INITIAL){
		printf("lexer error\n");
		exit(0);
	}
    return 1;
}








