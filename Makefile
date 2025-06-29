FILE ?= inconnu

all:

	bison -d langage.y
	flex langage.l
	gcc langage.tab.c lex.yy.c utils.c -o bin/compilateur

clean:

	rm -f langage.tab.c langage.tab.h lex.yy.c bin/compilateur bin/programme output.c
	clear

test:

	./bin/compilateur tests/$(FILE)

exec:

	gcc output.c -o bin/programme
	./bin/programme
