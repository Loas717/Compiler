#include "semantic.h"
#include "stdio.h"

int retorna_maior_tipo(int t1, int t2){
    if(t1==FLOAT || t2==FLOAT)
        return FLOAT;
    if(t1==INT || t2==INT)
        return INT;
    if(t1==CHAR || t2==CHAR)
        return CHAR;
}
int verifica_tipo(int t1, int t2){
    //printf("%d %d", t1, t2);
    if (t1 == t2) return 1;
    if ((t1 == INT || t1 == CHAR) && t2 == FLOAT) return 0;
    if ((t2 == INT || t2 == CHAR) && t1 == FLOAT) return 0;
    if (t1 == CHAR && t2 == INT) return 0;
    if (t2 == CHAR && t1 == INT) return 0;
    return 1;  
}

int verifica_tipos_atrib(){
    //???
}