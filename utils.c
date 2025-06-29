#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "utils.h"

char* concat3(const char* a, const char* b, const char* c) {
    size_t len = strlen(a) + strlen(b) + strlen(c) + 1;
    char* result = malloc(len);
    if (!result) {
        fprintf(stderr, "Erreur d'allocation mémoire\n");
        exit(1);
    }
    strcpy(result, a);
    strcat(result, b);
    strcat(result, c);
    return result;
}
