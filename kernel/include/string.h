#ifndef STRING_H
#define STRING_H

#include "types.h"

/* String manipulation functions */
size_t strlen(const char* str);
char* strcpy(char* dest, const char* src);
char* strncpy(char* dest, const char* src, size_t n);
char* strcat(char* dest, const char* src);
char* strncat(char* dest, const char* src, size_t n);
int strcmp(const char* str1, const char* str2);
int strncmp(const char* str1, const char* str2, size_t n);
char* strchr(const char* str, int c);
char* strrchr(const char* str, int c);
char* strstr(const char* haystack, const char* needle);

/* Memory manipulation functions */
void* memset(void* ptr, int value, size_t num);
void* memcpy(void* dest, const void* src, size_t num);
void* memmove(void* dest, const void* src, size_t num);
int memcmp(const void* ptr1, const void* ptr2, size_t num);
void* memchr(const void* ptr, int value, size_t num);

/* Memory zeroing utility */
void bzero(void* ptr, size_t num);

/* String conversion functions */
int atoi(const char* str);
long atol(const char* str);
char* itoa(int value, char* str, int base);
char* ltoa(long value, char* str, int base);
char* utoa(unsigned int value, char* str, int base);

/* String utility functions */
char* strdup(const char* str);
void strrev(char* str);
char* strtok(char* str, const char* delim);
char* strtok_r(char* str, const char* delim, char** saveptr);

/* Case conversion */
int tolower(int c);
int toupper(int c);
int isalpha(int c);
int isdigit(int c);
int isalnum(int c);
int isspace(int c);
int isprint(int c);

/* String formatting helpers */
void int_to_string(int value, char* buffer, int base);
void uint_to_string(unsigned int value, char* buffer, int base);
void hex_to_string(unsigned int value, char* buffer, bool uppercase);

#endif /* STRING_H */