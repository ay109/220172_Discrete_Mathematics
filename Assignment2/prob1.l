%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#define MAX_STR_LEN 1024
#define MAX_LEXEMES 1024

int line_num = 1;

// Structures to store lexemes and their counts
typedef struct {
    char lexeme[MAX_STR_LEN];
    int count;
} Lexeme;

Lexeme keywords[MAX_LEXEMES];
Lexeme operators[MAX_LEXEMES];
Lexeme delimiters[MAX_LEXEMES];
Lexeme identifiers[MAX_LEXEMES];
Lexeme strings[MAX_LEXEMES];
Lexeme integers[MAX_LEXEMES];

int keyword_count = 0;
int operator_count = 0;
int delimiter_count = 0;
int identifier_count = 0;
int string_count = 0;
int integer_count = 0;

void add_lexeme(Lexeme lexemes[], int *count, const char *lexeme) {
    for (int i = 0; i < *count; i++) {
        if (strcmp(lexemes[i].lexeme, lexeme) == 0) {
            lexemes[i].count++;
            return;
        }
    }
    strcpy(lexemes[*count].lexeme, lexeme);
    lexemes[*count].count = 1;
    (*count)++;
}

void print_lexemes(const char *type, Lexeme lexemes[], int count) {
    for (int i = 0; i < count; i++) {
        printf("%s\t%d\t%s\n", type, lexemes[i].count, lexemes[i].lexeme);
    }
}

void yyerror(const char *s);
int yywrap(void);
%}

%x STRING_SINGLE
%x STRING_DOUBLE

%%
"ARRAY"|"BEGIN"|"BOOLEAN"|"COMMENT"|"CONTINUE"|"DO"|"DOUBLE"|"ELSE"|"END"|"FALSE"|"FOR"|"IF"|"INTEGER"|"LABEL"|"LIST"|"LONG"|"OWN"|"PROCEDURE"|"STEP"|"SWITCH"|"THEN"|"TRUE"|"UNTIL"|"VALUE"|"WHILE" {
    add_lexeme(keywords, &keyword_count, yytext);
}

"AND"|"OR"|"LEQ"|"LT"|"GEQ"|"GT"|"NOT"|"EQL"|"NEQ"|":="|"+"|"-"|"*"|"/"|"%"|"^"|"\\|"|"&"|"<<"|">>"|"<="|">=" {
    add_lexeme(operators, &operator_count, yytext);
}

[ \t\r\n\f]+ {
    if (*yytext == '\n') line_num++;
}

";"|":"|","|"\\("|"\\)"|"\\["|"\\]"|"\\{"|"\\}"|"'" {
    add_lexeme(delimiters, &delimiter_count, yytext);
}

[0-9]+ {
    add_lexeme(integers, &integer_count, yytext);
}

0[xX][0-9a-fA-F]+ {
    printf("HEXADECIMAL\t1\t%s\n", yytext);
}

[0-9]*\.[0-9]{1,6} {
    printf("FLOATING_POINT\t1\t%s\n", yytext);
}

\"([^\"\\]|\\[\"\\nt])*\" {
    add_lexeme(strings, &string_count, yytext);
}

\'([^\'\\]|\\[\'\\nt])*\' {
    add_lexeme(strings, &string_count, yytext);
}

\"([^\"\\]*) {
    yyerror("Unterminated string (double quotes)");
}

\'([^\'\\]*) {
    yyerror("Unterminated string (single quotes)");
}

[a-zA-Z][a-zA-Z0-9]* {
    add_lexeme(identifiers, &identifier_count, yytext);
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

    print_lexemes("KEYWORD", keywords, keyword_count);
    print_lexemes("OPERATOR", operators, operator_count);
    print_lexemes("DELIMITER", delimiters, delimiter_count);
    print_lexemes("INTEGER", integers, integer_count);
    print_lexemes("STRING", strings, string_count);
    print_lexemes("IDENTIFIER", identifiers, identifier_count);

    return 0;
}
