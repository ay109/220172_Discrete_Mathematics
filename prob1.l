%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LEN 1000

int line_number = 1;
typedef struct Token {
    char lexeme[MAX_LEN];
    char type[MAX_LEN];
    int count;
} Token;

Token tokens[MAX_LEN];
int token_count = 0;

void add_token(const char* type, const char* lexeme);
void report_error(const char* msg);
void print_tokens();
int compare_tokens(const void* a, const void* b);

%}

%option noyywrap

%%

ARRAY|BEGIN|BOOLEAN|COMMENT|CONTINUE|DO|DOUBLE|ELSE|END|FALSE|FOR|IF|INTEGER|LABEL|LIST|LONG|OWN|PROCEDURE|STEP|SWITCH|THEN|TRUE|UNTIL|VALUE|WHILE {
    add_token("KEYWORD", yytext);
}

"+"|"/"|"%"|"^"|"&"|"AND"|"OR"|"LEQ"|"LT"|"GEQ"|"GT"|"NOT"|"EQL"|"NEQ" {
    add_token("OPERATOR", yytext);
}

[a-zA-Z][a-zA-Z0-9]* {
    add_token("IDENTIFIER", yytext);
}

\"[^\"]*\"|'[^']*' {
    add_token("STRING", yytext);
}

[ \t\r\n\f]+ {
    /* Ignore whitespace */
    if (*yytext == '\n') line_number++;
}

"(" {
    add_token("DELIMITER", "(");
}

")" {
    add_token("DELIMITER", ")");
}

"[" {
    add_token("DELIMITER", "[");
}

"]" {
    add_token("DELIMITER", "]");
}

"{" {
    add_token("DELIMITER", "{");
}

"}" {
    add_token("DELIMITER", "}");
}

0|([1-9][0-9]*) {
    add_token("INTEGER", yytext);
}

0x[0-9a-fA-F]+ {
    add_token("HEXADECIMAL", yytext);
}

[0-9]+\.[0-9]{1,6} {
    add_token("FLOATING_POINT", yytext);
}

{[^}]*} {
    /* Ignore comments */
}

<|>|! {
    report_error("Invalid operator");
}

\"[^"]* {
    report_error("Ill-formed string");
}

'[^']* {
    report_error("Ill-formed string");
}

. {
    report_error("Illegal character");
}

%%

void add_token(const char* type, const char* lexeme) {
    for (int i = 0; i < token_count; ++i) {
        if (strcmp(tokens[i].lexeme, lexeme) == 0) {
            tokens[i].count++;
            return;
        }
    }
    strcpy(tokens[token_count].type, type);
    strcpy(tokens[token_count].lexeme, lexeme);
    tokens[token_count].count = 1;
    token_count++;
}

void report_error(const char* msg) {
    fprintf(stderr, "Error on line %d: %s\n", line_number, msg);
    print_tokens();
    exit(1);
}

void print_tokens() {
    qsort(tokens, token_count, sizeof(Token), compare_tokens);
    printf("TOKEN\tCOUNT\tLEXEME\n");
    for (int i = 0; i < token_count; ++i) {
        printf("%s\t%d\t%s\n", tokens[i].type, tokens[i].count, tokens[i].lexeme);
    }
}

int compare_tokens(const void* a, const void* b) {
    return strcmp(((Token*)a)->lexeme, ((Token*)b)->lexeme);
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            fprintf(stderr, "Could not open file: %s\n", argv[1]);
            return 1;
        }
        yyin = file;
    }
    yylex();
    print_tokens();
    return 0;
}