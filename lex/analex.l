%{
#include <stdio.h>
#include "tokens.h"
#include "tabsimb.h"
int linha = 1;
%}
dig [0-9]
letra [a-zA-Z_]
%%
"int"  {return INT;}
"if"	{return IF;}	
">="  {return GE;} 	
"<="  {return LE;} 	
"=="  {return EQ;} 	
">"  {return '>';} 	
"<"  {return '<';} 		
"("	  {return '(';}
")"   {return ')';}
"{"	  {return '{';}
"}"   {return '}';}
";"   {return ';';}
"="   {return '=';}
"+"   {return '+';}
"-"   {return '-';}
"*"   {return '*';}
","   {return ',';}
"/"   {return '/';}
"!"   {return NOT;}
"and"   {return AND;}
"or"   {return OR;}
"while" {return WH;}
"else" {return ES;}
"return" {return RT;}
"float" {return FLOAT;}
"for" {return FOR;}
\"[^"]*\" {return STR;}
{dig}+("."{dig}+)?	{ return NUM;}
{letra}({letra}|{dig})*  { insere(yytext);
                    return ID;}  
[ \t\r] {}
\n	{ linha++; }
.	{printf("erro lexico na linha %d - %s\n",
            linha, yytext); }
%%
#ifndef yywrap
int yywrap() { return 1; }
#endif
void main(int argc, char **argv) {
int token,i=1;	
	yyin = fopen(argv[1],"r");
	token = yylex();
	while(token) {
		printf("%d) %d %s\n", i++, token, yytext);
		token = yylex();
	}
	imprime();
}
