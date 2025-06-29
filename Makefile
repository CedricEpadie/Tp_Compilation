FILE ?= inconnu

all:

	bison -d langage.y
	flex langage.l
	gcc langage.tab.c lex.yy.c -o compilateur

clean:

	rm -f langage.tab.c langage.tab.h lex.yy.c compilateur output.c programme
	clear

test:

	./compilateur tests/$(FILE)

exec:

	gcc output.c -o programme
	./programme
