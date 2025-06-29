%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void yyerror(const char* s);
int yylex();
int yyparse(void);
extern FILE* yyin;
FILE* output;

extern int yylineno;
extern char* yytext;    // texte du jeton fautif

#include <stdbool.h>

#define MAX_VARS 100
#define MAX_CODE 10000
char* variables[MAX_VARS];
int nb_vars = 0;
char code_buffer[MAX_CODE];
int code_length = 0;
int indent_level = 0;

bool variable_existe(const char* nom) {
    for (int i = 0; i < nb_vars; ++i) {
        if (strcmp(variables[i], nom) == 0) return true;
    }
    return false;
}

void ajouter_variable(const char* nom) {
    if (!variable_existe(nom)) {
        variables[nb_vars++] = strdup(nom);
    }
}

void print_indent() {
    for (int i = 0; i < indent_level; i++) {
        strncat(code_buffer, "\t", MAX_CODE - code_length - 1);
        code_length++;
    }
}

void append_to_buffer(const char* str) {
    if (str) {
        strncat(code_buffer, str, MAX_CODE - code_length - 1);
        code_length += strlen(str);
    }
}

// Fonction pour enlever guillemets d'une chaîne (ex: "Un" -> Un)
char* enlever_guillemets(const char* s) {
    size_t len = strlen(s);
    if (len >= 2 && s[0] == '"' && s[len - 1] == '"') {
        char* res = malloc(len - 1);
        strncpy(res, s + 1, len - 2);
        res[len - 2] = '\0';
        return res;
    }
    return strdup(s);
}

int main(int argc, char** argv) {
    if (argc != 2) {
        printf("Usage : %s fichier_source.fr\n", argv[0]);
        return 1;
    }

    FILE* source = fopen(argv[1], "r");
    if (!source) {
        perror("Erreur ouverture source");
        return 1;
    }

    yyin = source;
    output = fopen("output.c", "w");
    if (!output) {
        perror("Erreur ouverture output.c");
        return 1;
    }

    fprintf(output, "#include <stdio.h>\n\n");
    fprintf(output, "int main(void) {\n");
    indent_level++;

    code_length = 0;
    code_buffer[0] = '\0';
    yyparse();

    if (nb_vars > 0) {
        fprintf(output, "\tint ");
        for (int i = 0; i < nb_vars; i++) {
            fprintf(output, "%s%s", variables[i], (i == nb_vars - 1) ? ";\n" : ", ");
            free(variables[i]);
        }
    }

    // Ajout du code généré une seule fois
    print_indent();
    append_to_buffer("\n"); // pour sauter une ligne avant le code
    fprintf(output, "%s", code_buffer);

    fprintf(output, "\treturn 0;\n");
    fprintf(output, "}\n");

    fclose(output);
    fclose(source);
    return 0;
}
%}

%union {
    int entier;
    char* nom;
    char* code;
}

%define parse.error verbose


%token <nom> IDENTIFIANT TEXTE
%token <entier> NOMBRE

%token POUR SELON SI ALORS SINON FSI FSELON CAS DEUX_POINTS DEFAUT
%token FAIRE FPOUR FTANTQUE TANTQUE
%token AFFICHER LIRE

%token EGAL DIFF INFEG SUPEG INF SUP
%token ASSIGN PLUS MOINS FOIS DIV MOD
%token POINTVIRGULE VIRGULE PARENTHESE_OUVRANTE PARENTHESE_FERMANTE

%type <nom> expression
%type <code> assignment
%type <code> switch_body
%type <code> instruction
%type <code> iteration
%type <code> control_structure
%type <code> instructions
%type <code> cas_blocks
%type <code> defaut_block


%left EGAL DIFF
%left INF SUP INFEG SUPEG
%left PLUS MOINS
%left FOIS DIV MOD

%start programme

%%

programme:
    instructions {
        append_to_buffer($1);
        free($1);
    }
;

instructions:
    /* vide */ {
        $$ = strdup("");
    }
  | instructions instruction {
        char* buf = malloc(strlen($1) + strlen($2) + 1);
        strcpy(buf, $1);
        strcat(buf, $2);
        free($1);
        free($2);
        $$ = buf;
    }
  | instructions control_structure {
        char* buf = malloc(strlen($1) + strlen($2) + 1);
        strcpy(buf, $1);
        strcat(buf, $2);
        free($1);
        free($2);
        $$ = buf;
    }
;

instruction:
    assignment POINTVIRGULE {
        char buf[256];
        snprintf(buf, sizeof(buf), "%s;\n", $1);
        $$ = strdup(buf);
        free($1);
    }
  | LIRE IDENTIFIANT POINTVIRGULE {
        ajouter_variable($2);
        char buf[256];
        snprintf(buf, sizeof(buf), "scanf(\"%%d\", &%s);\n", $2);
        $$ = strdup(buf);
        free($2);
    }
    | AFFICHER PARENTHESE_OUVRANTE TEXTE PARENTHESE_FERMANTE POINTVIRGULE {
      char* txt_sans_guillemets = enlever_guillemets($3);
      char buf[256];
      snprintf(buf, sizeof(buf), "printf(\"%s\\n\");\n", txt_sans_guillemets);
      free(txt_sans_guillemets);
      free($3);
      $$ = strdup(buf);
  }

  | AFFICHER IDENTIFIANT POINTVIRGULE {
        ajouter_variable($2);
        char buf[256];
        snprintf(buf, sizeof(buf), "printf(\"%%d\\n\", %s);\n", $2);
        free($2);
        $$ = strdup(buf);
    }
;

assignment:
    IDENTIFIANT ASSIGN expression {
        ajouter_variable($1);
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s", $1, $3);
        free($1);
        free($3);
        $$ = strdup(buf);
    }
;

control_structure:
    SI PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE ALORS instructions FSI {
        char* res = malloc(strlen("if () {\n") + strlen($3) + strlen($6) + strlen("}\n") + 1);
        sprintf(res, "if (%s) {\n%s}\n", $3, $6);
        free($3);
        free($6);
        $$ = res;
    }
  | SI PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE ALORS instructions SINON instructions FSI {
        char* res = malloc(strlen("if () {\n") + strlen($3) + strlen($6) + strlen($8) + strlen("} else {\n}\n") + 1);
        sprintf(res, "if (%s) {\n%s} else {\n%s}\n", $3, $6, $8);
        free($3);
        free($6);
        free($8);
        $$ = res;
    }
  | TANTQUE PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE FAIRE instructions FTANTQUE {
        char* res = malloc(strlen("while () {\n") + strlen($3) + strlen($6) + strlen("}\n") + 1);
        sprintf(res, "while (%s) {\n%s}\n", $3, $6);
        free($3);
        free($6);
        $$ = res;
    }
  | POUR PARENTHESE_OUVRANTE assignment POINTVIRGULE expression POINTVIRGULE iteration PARENTHESE_FERMANTE FAIRE instructions FPOUR {
        char* res = malloc(strlen("for (;;) {\n") + strlen($3) + strlen($5) + strlen($7) + strlen($10) + strlen("}\n") + 1);
        sprintf(res, "for (%s; %s; %s) {\n%s}\n", $3, $5, $7, $10);
        free($3);
        free($5);
        free($7);
        free($10);
        $$ = res;
    }
  | FAIRE instructions TANTQUE PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE POINTVIRGULE {
        char* res = malloc(strlen("do {\n") + strlen($2) + strlen("} while ();") + strlen($5) + 2);
        sprintf(res, "do {\n%s} while (%s);\n", $2, $5);
        free($2);
        free($5);
        $$ = res;
    }
    | SELON PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE switch_body FSELON {
        char* buf = malloc(strlen($3) + strlen($5) + 64);
        sprintf(buf, "switch (%s) {\n%s}\n", $3, $5);
        $$ = buf;
        free($3);
        free($5);
    }

;

iteration:
    IDENTIFIANT ASSIGN expression {
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s", $1, $3);
        free($1);
        free($3);
        $$ = strdup(buf);
    }
;

expression:
    IDENTIFIANT {
        ajouter_variable($1);
        $$ = strdup($1);
        free($1);
    }
  | NOMBRE {
        char buffer[32];
        sprintf(buffer, "%d", $1);
        $$ = strdup(buffer);
    }
  | expression PLUS expression {
        char* buf = malloc(strlen($1) + strlen($3) + 4);
        sprintf(buf, "%s+%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression MOINS expression {
        char* buf = malloc(strlen($1) + strlen($3) + 4);
        sprintf(buf, "%s-%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression FOIS expression {
        char* buf = malloc(strlen($1) + strlen($3) + 4);
        sprintf(buf, "%s*%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression DIV expression {
        char* buf = malloc(strlen($1) + strlen($3) + 4);
        sprintf(buf, "(%s/%s)", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression MOD expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "(%s%%%s)", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression EGAL expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s==%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression DIFF expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s!=%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression INF expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s<%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | expression SUP expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s>%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
    | expression INFEG expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s<=%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
    | expression SUPEG expression {
        char* buf = malloc(strlen($1) + strlen($3) + 5);
        sprintf(buf, "%s>=%s", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
  | PARENTHESE_OUVRANTE expression PARENTHESE_FERMANTE {
        $$ = $2;
    }
;

cas_blocks:
    cas_blocks CAS NOMBRE DEUX_POINTS instructions {
        char* buf = malloc(strlen($1) + 64 + strlen($5) + 1);
        sprintf(buf, "%scase %d:\n%s\tbreak;\n", $1, $3, $5);
        free($1);
        free($5);
        $$ = buf;
    }
  | CAS NOMBRE DEUX_POINTS instructions {
        char* buf = malloc(64 + strlen($4) + 1);
        sprintf(buf, "case %d:\n%s\tbreak;\n", $2, $4);
        free($4);
        $$ = buf;
    }
;


defaut_block:
    DEFAUT DEUX_POINTS instructions {
        char* buf = malloc(64 + strlen($3));
        sprintf(buf, "default:\n%s", $3);
        free($3);
        $$ = buf;
    }
  | /* vide */ {
        $$ = strdup("");
    }
;

switch_body:
    cas_blocks defaut_block {
        char* buf = malloc(strlen($1) + strlen($2) + 1);
        strcpy(buf, $1);
        strcat(buf, $2);
        free($1);
        free($2);
        $$ = buf;
    }
;

%%

void yyerror(const char* s) {
    fprintf(stderr, "Erreur de syntaxe à la ligne %d : %s\n", yylineno, s);
    if (yytext)
        fprintf(stderr, "Jeton fautif : '%s'\n", yytext);
}

