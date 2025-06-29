%{
#include "langage.tab.h"
#include <stdio.h>
#include <stdlib.h>  // pour atoi

%}

%option noyywrap
%option yylineno

%%

"mpo"        { return POUR; }
"yebega"       { return SELON; }
"soo"          { return SI; }
"tebo"       { return ALORS; }
"tesooba"       { return SINON; }
"owusoo"         { return FSI; }
"owuyebega"      { return FSELON; }
"ndamba"         { return CAS; }
"aneayem"      { return DEFAUT; }
"ke"       { return FAIRE; }
"owumpo"       { return FPOUR; }
"owuangaha"    { return FTANTQUE; }
"angaha"     { return TANTQUE; }
"yebege"    { return AFFICHER; }
"lange"        { return LIRE; }
":"           { return DEUX_POINTS; }

[0-9]+        { yylval.entier = atoi(yytext); return NOMBRE; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.nom = strdup(yytext); return IDENTIFIANT; }

"=="          { return EGAL; }
"!="          { return DIFF; }
"<="          { return INFEG; }
">="          { return SUPEG; }
"<"           { return INF; }
">"           { return SUP; }

"="           { return ASSIGN; }
";"           { return POINTVIRGULE; }
","           { return VIRGULE; }
"("           { return PARENTHESE_OUVRANTE; }
")"           { return PARENTHESE_FERMANTE; }
"+"           { return PLUS; }
"-"           { return MOINS; }
"*"           { return FOIS; }
"/"           { return DIV; }
"%"           { return MOD; }

\"([^\\\"]*)\" { yylval.nom = strdup(yytext); return TEXTE; }

[ \t\r]+      ;               // Ignorer espaces, tabulations, retours chariot
\n            { /* yylineno est géré automatiquement */ }

"//".*        { /* commentaire ignoré */ }


.             {
                fprintf(stderr, "Erreur lexicale : caractère inconnu '%s' à la ligne %d\n", yytext, yylineno);
                exit(EXIT_FAILURE);
              }

%%
