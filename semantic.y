%{ 
/* Para simplificar a notação, S é para sintetizar. A atualizar. V verificar */
#include "analex.c" 
#include "codigo.h" 
/* Funcoes auxiliares podem ser declaradas aqui */
void verifica_var_declarada(int tipo);
void verifica_ID_declarada(int tipo);
%}

%union{
	struct no{
		int place;
		char *code;
		int tipo;
	} node;
	int val;
	struct ids{
		int ids[50];
		int tam;
		char *code;
	} id_list;
}

%token <node> NUM 
%token <val> ID 
%token WHILE
%token IF 
%token ELSE
%token ENDIF
%token CHAR
%token INT
%token FLOAT
%token VOID
%token OR
%token AND
%token NOT
%token GE
%token LE
%token EQ
%token NEQ
%token DO
%token STRING

%type <val> Type TypeF
%type <id_list> IDs ParamList ArgList
%type <node> Atribuicao Exp Function Prog Statement Statement_Seq
%type <node> If While Compound_Stt DoWhile FunctionCall 

%right '='

%left OR
%left AND

%nonassoc EQ NEQ

%left '>' '<' GE LE

%left '+' '-'
%left '*' '/' '%'

%right NOT

%right '(' '['


%start ProgL
%% 
ProgL : Prog { printf("%s",$1.code);} 
    ;
    
Prog : Prog Function { create_cod(&$$.code); insert_cod(&$$.code,$1.code); insert_cod(&$$.code,$2.code); } /* S código. */
	| Function {create_cod(&$$.code); insert_cod(&$$.code,$1.code); }
	;	

Function :
	TypeF ID '(' ParamList ')' '{' Decls Statement_Seq '}'  {
		set_type($2, $1);
		for(int i=0;i<$4.tam;i++){
			Tabela[$2].arg_list[i]=$4.ids[i];
			Tabela[$2].tam_arg_list++;
		}
		Funct(&$$, $2,$8); 
	} 
	| TypeF ID '(' ')' '{' Decls Statement_Seq '}'  {
		set_type($2, $1);
		Funct(&$$, $2, $7);
		} 
	;
	
FunctionCall :
    ID '(' ArgList ')' {

		verifica_ID_declarada(Tabela[$1].tipo); 
	Call(&$$, $1, $3);
	} 
	| ID '(' ')' {verifica_ID_declarada(Tabela[$1].tipo);} 
    ;
    
ArgList:
    Exp ',' ArgList {		
		$$.tam = $3.tam + 1;
		for (int i = 0; i < $3.tam; i++) {
            $$.ids[i] = $3.ids[i];  
        }
        $$.ids[$3.tam] = $1.place; 
		create_cod(&$$.code); insert_cod(&$$.code,$1.code);insert_cod(&$$.code,$3.code);
		} 
    | Exp  {
		$$.tam = 1;
		$$.ids[0] = $1.place; 
		create_cod(&$$.code); insert_cod(&$$.code,$1.code);
	} 
    ;

ParamList: 
    ParamList ',' Type ID  {
		$$.tam = $1.tam + 1;
		for (int i = 0; i < $1.tam; i++) {
            $$.ids[i] = $1.ids[i];  
        }
        $$.ids[$1.tam] = $4; 
		set_type($4, $3);
	} 
    | Type ID {
		$$.tam = 1;
		$$.ids[0] = $2;    
		set_type($2, $1);
	} 
	; 
		
Decls:
	  Decl ';' Decls  
	| 
	;

Decl:
	Type IDs {
        for (int i = 0; i < $2.tam; i++) {
            set_type($2.ids[i], $1);
        }
	} 
	; 
	
IDs :
	  IDs ',' ID {
		$$.ids[$$.tam] = $3;  
        $$.tam++; 
	  } 
	| IDs ',' Atribuicao {		
		$$.ids[$$.tam] = $3.place;  
        $$.tam++; 
		}  
	| IDs ',' ID '[' NUM ']' {
		$$.ids[$$.tam] = $3;  
        $$.tam++; 
	} 
	| ID '[' NUM ']' {
		$$.ids[$$.tam] = $1;  
        $$.tam++; 
	} 
	| ID {
		$$.ids[$$.tam] = $1;  
        $$.tam++; 
	} 
	| Atribuicao {		
		$$.ids[$$.tam] = $1.place;  
        $$.tam++; 
		} 
	;
	
TypeF :
	  VOID {$$=VOID;} 
	| Type
	;

Type :
	  INT {$$=INT;} 
	| CHAR {$$=CHAR;}
	| FLOAT {$$=FLOAT;} 
	;
			
Statement_Seq :
	Statement Statement_Seq {create_cod(&$$.code); insert_cod(&$$.code,$1.code);insert_cod(&$$.code,$2.code);} 
	| Statement { create_cod(&$$.code); insert_cod(&$$.code,$1.code);} 
	;
		
Statement: 
	  Atribuicao ';' {verifica_var_declarada(Tabela[$1.place].tipo); verifica_tipo(Tabela[$1.place].tipo, $1.tipo); create_cod(&$$.code); insert_cod(&$$.code,$1.code);/*verifica_tipos_atrib(Tabela[$1.place].tipo, $1.tipo);*/} 
	| If  {create_cod(&$$.code); insert_cod(&$$.code,$1.code);}
	| While {create_cod(&$$.code); insert_cod(&$$.code,$1.code);}
	| DoWhile {create_cod(&$$.code); insert_cod(&$$.code,$1.code);}
	| FunctionCall ';' {create_cod(&$$.code); insert_cod(&$$.code,$1.code);}   
	;

Compound_Stt :
	  Statement {create_cod(&$$.code); insert_cod(&$$.code,$1.code);}
	| '{' Statement_Seq '}' {/* $$ = $2; */create_cod(&$$.code); insert_cod(&$$.code,$2.code);} 
	;
		
If :
	  IF '(' Exp ')' Compound_Stt ENDIF {If(&$$, &$3, &$5);} 
	| IF '(' Exp ')' Compound_Stt ELSE Compound_Stt ENDIF {IfElse(&$$, &$3, &$5, &$7);} 
	;

While:
	WHILE '(' Exp ')' Compound_Stt  {While(&$$,&$3, &$5);} 
	;

DoWhile:
	DO Compound_Stt WHILE '(' Exp ')' ';' {} 
	;
			
Atribuicao : ID '[' NUM ']' '=' Exp {
		if(!verifica_tipo(Tabela[$1].tipo,$6.tipo)){
			yyerror("Tipos incompatíveis");
		}
	$$.place=$1;
	Atrib(&$$,&$6); 
	} 
    | ID '=' Exp {
		if(!verifica_tipo(Tabela[$1].tipo,$3.tipo)){
			yyerror("Tipos incompatíveis");
		}
		Atrib(&$$, &$3);
		} 
	;
				
Exp :
	Exp '+' Exp { 
		$$.tipo=retorna_maior_tipo($1.tipo,$3.tipo);Operation(&$$, $1, $3,'+');} 
	| Exp '-' Exp {
		$$.tipo=retorna_maior_tipo($1.tipo,$3.tipo); Operation(&$$, $1, $3,'-'); } 
	| Exp '*' Exp {
		$$.tipo=retorna_maior_tipo($1.tipo,$3.tipo);Operation(&$$, $1, $3,'*');} 
	| Exp '/' Exp {
		$$.tipo=retorna_maior_tipo($1.tipo,$3.tipo);Operation(&$$, $1, $3,'/');} 
	| Exp '>' Exp {
		$$.tipo=INT;
		ExpRel(&$$,$1,$3,'>');
	} 
	| Exp '<' Exp {$$.tipo=INT; ExpRel(&$$,$1,$3,'<');} 
	| Exp GE Exp {$$.tipo=INT;} 
	| Exp LE Exp {$$.tipo=INT;} 
	| Exp EQ Exp {$$.tipo=INT;} 
	| Exp NEQ Exp {$$.tipo=INT;}
	| Exp OR Exp {$$.tipo=INT;} 
	| Exp AND Exp {$$.tipo=INT;} 
	| NOT Exp {} 
	| '(' Exp ')' {$$.tipo=$2.tipo;$$.place=$2.place; create_cod(&$$.code); insert_cod(&$$.code,$2.code);} 
	| NUM { Li(&$$,$1.place);}
	| ID '[' NUM ']' {		
		if((Tabela[$1].tipo!=$3.tipo)){
			if(Tabela[$1].tipo==INT){
				yyerror("Indices de vetor não inteiro");
			}
			if(Tabela[$1].tipo==CHAR){
				yyerror("Indices de vetor não char");
			}
			if(Tabela[$1].tipo==FLOAT){
				yyerror("Indices de vetor não flutuante");
			}
		}
		verifica_var_declarada(Tabela[$1].tipo);
		int i=procura(Tabela[$1].nome);
		$$.place=i;
		create_cod(&$$.code); 
		}  
	| ID  {verifica_var_declarada(Tabela[$1].tipo);
	int i=procura(Tabela[$1].nome);
	$$.place=i;
	create_cod(&$$.code); 
	} 
	| STRING {create_cod(&$$.code);} 
	;   
	
	
%%  
int main(int argc, char **argv) {     
	yyin = fopen(argv[1],"r");
	yyparse();      
} 

void verifica_var_declarada(int tipo){
	if(tipo==CHAR || tipo==INT || tipo==FLOAT){
        return;
	}else{
		yyerror("Uso de variável não declarada");
	}
}
void verifica_ID_declarada(int tipo){
	if(tipo==CHAR || tipo==INT || tipo==FLOAT || tipo == VOID){
        return;
	}else{
		yyerror("Uso de identificador nao declarado");
	}
}