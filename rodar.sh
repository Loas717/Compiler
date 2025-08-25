lex -o analex.c analex.l
yacc -o semantic.c semantic.y -d
gcc -o semantic semantic.c -lfl
