#include "semantic.h"
#include "listacodigo.h"

int temp=-1;
int newTemp() {
	return temp--;
}

void freeTemp() {
	temp++;
}
int label = 0;
int newLabel() {
	return ++label;
}

char reg1[5];
char reg2[5];
char reg_temp[5];
void getName(int num, char *name) {
  if (num >= 0 ) {
    sprintf(name,"$s%d",num);
  }
  else 
    sprintf(name,"$t%d",-(num+1));
}

/* Geração de código para criar uma função. Exemplo */
void Funct(struct no* Funct, int Id, struct no Comandos) {
	create_cod(&Funct->code);
	obtemNome(Id);
	sprintf(instrucao,"%s:\n",nome);
	insert_cod(&Funct->code,instrucao);
	insert_cod(&Funct->code,Comandos.code);
	if (strcmp(nome,"main")==0) {
		sprintf(instrucao,"\tli $v0,10\n"); 
		insert_cod(&Funct->code,instrucao);
		sprintf(instrucao,"\tsyscall\n\n");
		insert_cod(&Funct->code,instrucao);					
	}
	else {
		sprintf(instrucao,"\tjr $ra\n\n"); 
		insert_cod(&Funct->code,instrucao);
	}
}

/* Função pre-implementada para lidar com argumentos de forma simples */
void adiciona_argumentos(char **code, int id, struct ids Args){
  struct symbol simbolo = Tabela[id];
  char name_param[5];
  char name_arg[5];
  for(int i = 0; i<simbolo.tam_arg_list;i++){
		getName(simbolo.arg_list[i], name_param);
		getName(Args.ids[i], name_arg);
		sprintf(instrucao,"\tmove %s,%s\n",name_param,name_arg);
		insert_cod(code,instrucao);
	}
}

/* Geração de código para chamada de função */
void Call(struct no* Call, int Id, struct ids Args) {
	create_cod(&Call->code);
    adiciona_argumentos(&Call->code, Id, Args);
    sprintf(instrucao, "\tjal %s\n", Tabela[Id].nome);
    insert_cod(&Call->code, instrucao);
}


/* Geração de código para chamada de função sem argumentos */
void Call_blank() {
	//???
}

/* Geração de código para atribuições */
void Atrib(struct no *Var, struct no *Exp) {
	//???
    char name_dest[5], name_src[5];
    create_cod(&Var->code);
    insert_cod(&Var->code, Exp->code);
    getName(Var->place, name_dest);  
    getName(Exp->place, name_src);  
    sprintf(instrucao, "\tmove %s,%s\n", name_dest, name_src);
    insert_cod(&Var->code, instrucao);  
}

/* Geração de código para carregar constantes */
void Li(struct no *Exp, int num) {
	char name_dest[5];
	create_cod(&Exp->code);
	Exp->place=newTemp();
	getName(Exp->place,name_dest);
	sprintf(instrucao,"\tli %s,%d\n",name_dest,num);
	insert_cod(&Exp->code,instrucao);
}

/* Geração de código para qualquer expressão relacional referente parâmetros */
void ExpRel(struct no *Exp, struct no Exp1, struct no Exp2, char op) { 
	char name_reg1[5];
    char name_reg2[5];
    char name_temp[5];
    char true_label[10], end_label[10];
    Exp->place = newTemp();
    create_cod(&Exp->code);
    insert_cod(&Exp->code, Exp1.code); 
    insert_cod(&Exp->code, Exp2.code);
    getName(Exp1.place, name_reg1);
    getName(Exp2.place, name_reg2);
    getName(Exp->place, name_temp); 
    sprintf(end_label, "L%d", newLabel()); 
	sprintf(instrucao, "\tli %s,1\n", name_temp);
	insert_cod(&Exp->code, instrucao);
	if(op=='<'){
		sprintf(instrucao, "\tblt %s,%s,%s\n", name_reg1, name_reg2, end_label);
	}
	if(op=='>'){
		sprintf(instrucao, "\tbgt %s,%s,%s\n", name_reg1, name_reg2, end_label);
	}
	insert_cod(&Exp->code, instrucao);
    sprintf(instrucao, "\tli %s,0\n", name_temp);
    insert_cod(&Exp->code, instrucao);
    sprintf(instrucao, "%s:\n", end_label);
    insert_cod(&Exp->code, instrucao);
}

/* Geração de código para ifs sem else */
void If(struct no *Var, struct no *Cond, struct no *If)  {  
    char end_label[10];
    sprintf(end_label, "L%d", newLabel());  
    create_cod(&Var->code);
    insert_cod(&Var->code, Cond->code);
    char cond_reg[5];
    getName(Cond->place, cond_reg);  
    sprintf(instrucao, "\tbeq %s,0,%s\n", cond_reg, end_label);
    insert_cod(&Var->code, instrucao);
    insert_cod(&Var->code, If->code);
    sprintf(instrucao, "%s:\n", end_label);
    insert_cod(&Var->code, instrucao);
}

/* Geração de código para qualquer expressão aritmética referente parâmetros */
void Operation(struct no *Exp, struct no Exp1, struct no Exp2, char op){
	char name_reg1[5];
	char name_reg2[5];
	char name_temp[5];
	Exp->place = newTemp();
	create_cod(&Exp->code);
	insert_cod(&Exp->code,Exp1.code);
	insert_cod(&Exp->code,Exp2.code);
	getName(Exp1.place,name_reg1);
	getName(Exp2.place,name_reg2);
    
	getName(Exp->place,name_temp);
	if(op=='+'){
		sprintf(instrucao,"\tadd %s,%s,%s\n",name_temp,name_reg1, name_reg2);
	}
	if(op=='-'){
		sprintf(instrucao,"\tsub %s,%s,%s\n",name_temp,name_reg1, name_reg2);
	}
	if(op=='*'){
		sprintf(instrucao,"\tmult %s,%s,%s\n",name_temp,name_reg1, name_reg2);
	}
	if(op=='/'){
		sprintf(instrucao,"\tdiv %s,%s,%s\n",name_temp,name_reg1, name_reg2);
	}
	insert_cod(&Exp->code,instrucao);
}

/* Geração de código para ifs com else */
void IfElse(struct no *Var, struct no *Cond, struct no *If, struct no *Else) {  
    char else_label[10], end_label[10];
    sprintf(else_label, "L%d", newLabel()); 
    sprintf(end_label, "L%d", newLabel()); 
    create_cod(&Var->code);
    insert_cod(&Var->code, Cond->code);
    char cond_reg[5];
    getName(Cond->place, cond_reg);
	//printf("%s",cond_reg);
    sprintf(instrucao, "\tbeq %s,0,%s\n", cond_reg, else_label); 
    insert_cod(&Var->code, instrucao);
    insert_cod(&Var->code, If->code);
    sprintf(instrucao, "\tj %s\n", end_label);
    insert_cod(&Var->code, instrucao);
    sprintf(instrucao, "%s:\n", else_label);
    insert_cod(&Var->code, instrucao);
    insert_cod(&Var->code, Else->code);
    sprintf(instrucao, "%s:\n", end_label);
    insert_cod(&Var->code, instrucao);
}


/* Geração de código para whiles */
void While(struct no *Var,struct no *Condition, struct no *Body) {  
    char start_label[10], end_label[10];
    char cond_reg[5];
    sprintf(start_label, "L%d", newLabel());  
    sprintf(end_label, "L%d", newLabel());  
    create_cod(&Var->code);
	sprintf(instrucao, "%s:\n", start_label);
    insert_cod(&Var->code, instrucao);
    insert_cod(&Var->code, Condition->code);
    getName(Condition->place,cond_reg);
    sprintf(instrucao, "\tbeq %s,0,%s\n", cond_reg, end_label);  
    insert_cod(&Var->code, instrucao);
    insert_cod(&Var->code, Body->code);
    sprintf(instrucao, "\tj %s\n", start_label);  
    insert_cod(&Var->code, instrucao);
    sprintf(instrucao, "%s:\n", end_label);
    insert_cod(&Var->code, instrucao);
}


/* Geração de código para do whiles */
void DoWhile() {  
	//???
}