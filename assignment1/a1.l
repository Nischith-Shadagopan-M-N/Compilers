%x	comm0	comm1

%{
	#include <stdlib.h>
	#include "y.tab.h"
	void yyerror(char *);
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
encpre	u8|u|U|L
charpre	[LUu]

%%

break	return BREAK;

case	return CASE;

char	return CHAR;

continue	return CONTINUE;

default	return DEFAULT;

do	return DO;

double	return DOUBLE;

else	return ELSE;

extern	return EXTERN;

float	return FLOAT;

for	return FOR;

if	return IF;

int	return INT;

long	return LONG;

return	return RETURN;

short	return SHORT;

sizeof	return SIZEOF;

struct	return STRUCT;

switch	return SWITCH;

void	return VOID;

while	return WHILE;

"/""/".*	;

"/""*"	{BEGIN(comm0);}

<comm0>"*"	{BEGIN(comm1);}

<comm0>[^*]	;

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

({charpre}?)"'"([^"'""\\"]|("\\".))+"'"	return CHARCONST;

({encpre}?)"\""([^"\"""\\"]|("\\".))*"\""	return STRING;

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

"\["		return '[';

"\]"		return ']';

"\("		return '(';

"\)"		return ')';

"\{"		return '{';

"\}"		return '}';

"\."		return '.';

"&"		return '&';

"\*"		return '*';

"\+"		return '+';

"-"		return '-';

"~"		return '~';

"!"		return '!';

"\/"		return '/';

"\%"		return '%';

"\<"		return '<';

"\>"		return '>';

"\^"		return '^';

"\|"		return '|';

";"		return ';';

"="		return '=';

","		return ',';

"#"		return '#';

[ \n\t\v\f]	;

.	;

%%

int yywrap(void) {
	if(YY_START != INITIAL){
		printf("***lexing terminated*** [lexer error]: ill-formed comment\n");
		exit(0);
	}
    return 1;
}








