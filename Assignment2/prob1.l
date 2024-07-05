%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#define MAX_STR_LEN 1024
#define MAX_LEXEMES 1024

int line_num = 1;

typedef struct {
    char type[MAX_STR_LEN];
    char lexeme[MAX_STR_LEN];
    int count;
} Lexeme;

Lexeme lexemes[MAX_LEXEMES];
int lexeme_count = 0;

void add_lexeme(const char *type, const char *lexeme) {
    for (int i = 0; i < lexeme_count; i++) {
        if (strcmp(lexemes[i].lexeme, lexeme) == 0 && strcmp(lexemes[i].type, type) == 0) {
            lexemes[i].count++;
            return;
        }
    }
    strcpy(lexemes[lexeme_count].type, type);
    strcpy(lexemes[lexeme_count].lexeme, lexeme);
    lexemes[lexeme_count].count = 1;
    lexeme_count++;
}

int compare_lexemes(const void *a, const void *b) {
    return strcmp(((Lexeme *)a)->lexeme, ((Lexeme *)b)->lexeme);
}

void print_lexemes() {
    qsort(lexemes, lexeme_count, sizeof(Lexeme), compare_lexemes);
    printf("%-10s %-7s %-20s\n", "TOKEN", "COUNT", "LEXEME");
    for (int i = 0; i < lexeme_count; i++) {
        printf("%-10s %-7d %-20s\n", lexemes[i].type, lexemes[i].count, lexemes[i].lexeme);
    }
}

void yyerror(const char *s);
int yywrap(void);
%}

%x STRING_SINGLE
%x STRING_DOUBLE

%%

[ \t\r\n\f]+ {
    if (*yytext == '\n') line_num++;
}

";"|":"|","|"["|"]"|"{"|"}"|"("|")" {
    add_lexeme("DELIMITER", yytext);
}

"ARRAY"|"BEGIN"|"BOOLEAN"|"COMMENT"|"CONTINUE"|"DO"|"DOUBLE"|"ELSE"|"END"|"FALSE"|"FOR"|"IF"|"INTEGER"|"LABEL"|"LIST"|"LONG"|"OWN"|"PROCEDURE"|"STEP"|"SWITCH"|"THEN"|"TRUE"|"UNTIL"|"VALUE"|"WHILE" {
    add_lexeme("KEYWORD", yytext);
}

"AND"|"OR"|"LEQ"|"LT"|"GEQ"|"GT"|"NOT"|"EQL"|"NEQ"|":="|"+"|"-"|"*"|"/"|"%"|"^"|"|"|"&"|"<<"|">>"|"<="|">=" {
    add_lexeme("OPERATOR", yytext);
}

[0-9]+ {
    add_lexeme("INTEGER", yytext);
}

0[xX][0-9a-fA-F]+ {
    add_lexeme("HEXADECIMAL", yytext);
}

[0-9]*\.[0-9]{1,6} {
    add_lexeme("FLOATING_POINT", yytext);
}

\"([^\"\\]|\\[\"\\nt])*\" {
    add_lexeme("STRING", yytext);
}

\'([^\'\\]|\\[\'\\nt])*\' {
    add_lexeme("STRING", yytext);
}

\"([^\"\\]*) {
    yyerror("Unterminated string (double quotes)");
}

\'([^\'\\]*) {
    yyerror("Unterminated string (single quotes)");
}

[a-zA-Z][a-zA-Z0-9]* {
    add_lexeme("IDENTIFIER", yytext);
}

\{[^}]*\} {
    /* Ignore comments */
}

. {
    printf("Illegal character '%c' at line %d\n", *yytext, line_num);
}

%%

int yywrap() {
    return 1;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s at line %d\n", s, line_num);
}

int main(int argc, char **argv) {
    ++argv, --argc;  /* skip over program name */
    if (argc > 0)
        yyin = fopen(argv[0], "r");
    else
        yyin = stdin;

    yylex();

    print_lexemes();

    return 0;
}
