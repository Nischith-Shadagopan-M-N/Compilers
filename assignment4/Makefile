a.out: y.tab.cpp lex.yy.c
	g++ lex.yy.c y.tab.cpp -g
	@echo "Run the program as ./a.out <input.txt"

y.tab.cpp: a1.y 
	yacc -d a1.y -o y.tab.cpp

lex.yy.c: a1.l y.tab.hpp
	lex a1.l

clean:
	@rm -f lex.yy.c y.tab.hpp y.tab.cpp a.out

