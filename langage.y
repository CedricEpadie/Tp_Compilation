%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"

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

// Structure pour gérer les tableaux et matrices
typedef struct {
    char* nom;
    int taille1;
    int taille2;
    bool est_tableau;
    bool est_matrice;
} Variable;

Variable variables[MAX_VARS];
int nb_vars = 0;
char code_buffer[MAX_CODE];
int code_length = 0;
int indent_level = 0;

Variable* trouver_variable(const char* nom) {
    for (int i = 0; i < nb_vars; ++i) {
        if (strcmp(variables[i].nom, nom) == 0) return &variables[i];
    }
    return NULL;
}

bool variable_existe(const char* nom) {
    return trouver_variable(nom) != NULL;
}

void ajouter_variable(const char* nom) {
    if (!variable_existe(nom)) {
        variables[nb_vars].nom = strdup(nom);
        variables[nb_vars].taille1 = 0;
        variables[nb_vars].taille2 = 0;
        variables[nb_vars].est_tableau = false;
        variables[nb_vars].est_matrice = false;
        nb_vars++;
    }
}

void ajouter_tableau(const char* nom, int taille) {
    if (!variable_existe(nom)) {
        variables[nb_vars].nom = strdup(nom);
        variables[nb_vars].taille1 = taille;
        variables[nb_vars].taille2 = 0;
        variables[nb_vars].est_tableau = true;
        variables[nb_vars].est_matrice = false;
        nb_vars++;
    }
}

void ajouter_matrice(const char* nom, int lignes, int colonnes) {
    if (!variable_existe(nom)) {
        variables[nb_vars].nom = strdup(nom);
        variables[nb_vars].taille1 = lignes;
        variables[nb_vars].taille2 = colonnes;
        variables[nb_vars].est_tableau = false;
        variables[nb_vars].est_matrice = true;
        nb_vars++;
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

    // Déclaration des variables et tableaux
    for (int i = 0; i < nb_vars; i++) {
        if (variables[i].est_matrice) {
            fprintf(output, "\tint %s[%d][%d];\n", variables[i].nom, variables[i].taille1, variables[i].taille2);
        } else if (variables[i].est_tableau) {
            fprintf(output, "\tint %s[%d];\n", variables[i].nom, variables[i].taille1);
        } else {
            fprintf(output, "\tint %s;\n", variables[i].nom);
        }
        free(variables[i].nom);
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
%token AFFICHER LIRE TABLEAU MATRICE
%token INTERROGATION

%token EGAL DIFF INFEG SUPEG INF SUP
%token ASSIGN PLUS MOINS FOIS DIV MOD
%token POINTVIRGULE VIRGULE PARENTHESE_OUVRANTE PARENTHESE_FERMANTE
%token CROCHET_OUVRANT CROCHET_FERMANT

%type <nom> expression
%type <nom> acces_tableau
%type <nom> acces_matrice
%type <code> assignment
%type <code> switch_body
%type <code> instruction
%type <code> iteration
%type <code> control_structure
%type <code> instructions
%type <code> cas_blocks
%type <code> defaut_block
%type <code> declaration_tableau
%type <code> declaration_matrice

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
  | instructions declaration_tableau {
        char* buf = malloc(strlen($1) + strlen($2) + 1);
        strcpy(buf, $1);
        strcat(buf, $2);
        free($1);
        free($2);
        $$ = buf;
    }
    | instructions declaration_matrice {
        char* buf = malloc(strlen($1) + strlen($2) + 1);
        strcpy(buf, $1);
        strcat(buf, $2);
        free($1);
        free($2);
        $$ = buf;
    }
;

declaration_tableau:
    TABLEAU IDENTIFIANT CROCHET_OUVRANT NOMBRE CROCHET_FERMANT POINTVIRGULE {
        ajouter_tableau($2, $4);
        free($2);
        $$ = strdup(""); // Pas de code généré pour la déclaration
    }
;

declaration_matrice:
    MATRICE IDENTIFIANT CROCHET_OUVRANT NOMBRE CROCHET_FERMANT CROCHET_OUVRANT NOMBRE CROCHET_FERMANT POINTVIRGULE {
        ajouter_matrice($2, $4, $7);
        free($2);
        $$ = strdup(""); // Pas de code généré pour la déclaration
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
  | LIRE acces_tableau POINTVIRGULE {
        char buf[256];
        snprintf(buf, sizeof(buf), "scanf(\"%%d\", &%s);\n", $2);
        $$ = strdup(buf);
        free($2);
    }
  | LIRE acces_matrice POINTVIRGULE {
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
  | AFFICHER acces_tableau POINTVIRGULE {
        char buf[256];
        snprintf(buf, sizeof(buf), "printf(\"%%d\\n\", %s);\n", $2);
        free($2);
        $$ = strdup(buf);
    }
  | AFFICHER acces_matrice POINTVIRGULE {
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
  | acces_tableau ASSIGN expression {
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s", $1, $3);
        free($1);
        free($3);
        $$ = strdup(buf);
    }
  | acces_matrice ASSIGN expression {
        char buf[256];
        snprintf(buf, sizeof(buf), "%s = %s", $1, $3);
        free($1);
        free($3);
        $$ = strdup(buf);
    }
;

acces_tableau:
    IDENTIFIANT CROCHET_OUVRANT expression CROCHET_FERMANT {
        // Vérifier que la variable existe comme tableau
        Variable* var = trouver_variable($1);
        if (!var) {
            fprintf(stderr, "Erreur : tableau '%s' non déclaré\n", $1);
            exit(1);
        }
        if (!var->est_tableau) {
            fprintf(stderr, "Erreur : '%s' n'est pas un tableau\n", $1);
            exit(1);
        }
        
        char* buf = malloc(strlen($1) + strlen($3) + 4);
        sprintf(buf, "%s[%s]", $1, $3);
        free($1);
        free($3);
        $$ = buf;
    }
;

acces_matrice:
    IDENTIFIANT CROCHET_OUVRANT expression CROCHET_FERMANT CROCHET_OUVRANT expression CROCHET_FERMANT {
        // Vérifier que la variable existe comme matrice
        Variable* var = trouver_variable($1);
        if (!var) {
            fprintf(stderr, "Erreur : matrice '%s' non déclarée\n", $1);
            exit(1);
        }
        if (!var->est_matrice) {
            fprintf(stderr, "Erreur : '%s' n'est pas une matrice\n", $1);
            exit(1);
        }
        
        char* buf = malloc(strlen($1) + strlen($3) + strlen($6) + 6);
        sprintf(buf, "%s[%s][%s]", $1, $3, $6);
        free($1);
        free($3);
        free($6);
        $$ = buf;
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
  | acces_tableau {
        $$ = $1;
    }
    | acces_matrice {
        $$ = $1;
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
    | expression INTERROGATION expression DEUX_POINTS expression {
        // Génère : "(cond ? then : else)"
        char* part1 = concat3("(", $1, " ? ");
        char* part2 = concat3(part1, $3, " : ");
        free(part1);
        char* part3 = concat3(part2, $5, ")");
        free(part2);
        $$ = part3;
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