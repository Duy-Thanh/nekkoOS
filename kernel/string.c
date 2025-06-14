/*
 * String utility functions for nekkoOS kernel
 * Basic implementations of standard string and memory functions
 */

#include "include/string.h"
#include "include/types.h"

/* String length function */
size_t strlen(const char* str) {
    size_t len = 0;
    while (str[len])
        len++;
    return len;
}

/* String copy */
char* strcpy(char* dest, const char* src) {
    char* orig_dest = dest;
    while ((*dest++ = *src++));
    return orig_dest;
}

/* String copy with length limit */
char* strncpy(char* dest, const char* src, size_t n) {
    char* orig_dest = dest;
    while (n-- && (*dest++ = *src++));
    while (n-- > 0)
        *dest++ = '\0';
    return orig_dest;
}

/* String concatenation */
char* strcat(char* dest, const char* src) {
    char* orig_dest = dest;
    dest += strlen(dest);
    while ((*dest++ = *src++));
    return orig_dest;
}

/* String comparison */
int strcmp(const char* str1, const char* str2) {
    while (*str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }
    return *(const unsigned char*)str1 - *(const unsigned char*)str2;
}

/* String comparison with length limit */
int strncmp(const char* str1, const char* str2, size_t n) {
    while (n-- && *str1 && (*str1 == *str2)) {
        str1++;
        str2++;
    }
    if (n == SIZE_MAX)
        return 0;
    return *(const unsigned char*)str1 - *(const unsigned char*)str2;
}

/* Find character in string */
char* strchr(const char* str, int c) {
    while (*str) {
        if (*str == c)
            return (char*)str;
        str++;
    }
    return (*str == c) ? (char*)str : NULL;
}

/* Memory set function */
void* memset(void* ptr, int value, size_t num) {
    unsigned char* p = (unsigned char*)ptr;
    while (num--)
        *p++ = (unsigned char)value;
    return ptr;
}

/* Memory copy function */
void* memcpy(void* dest, const void* src, size_t num) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    while (num--)
        *d++ = *s++;
    return dest;
}

/* Memory move function (handles overlapping regions) */
void* memmove(void* dest, const void* src, size_t num) {
    unsigned char* d = (unsigned char*)dest;
    const unsigned char* s = (const unsigned char*)src;
    
    if (d < s) {
        while (num--)
            *d++ = *s++;
    } else {
        d += num;
        s += num;
        while (num--)
            *--d = *--s;
    }
    return dest;
}

/* Memory comparison */
int memcmp(const void* ptr1, const void* ptr2, size_t num) {
    const unsigned char* p1 = (const unsigned char*)ptr1;
    const unsigned char* p2 = (const unsigned char*)ptr2;
    
    while (num--) {
        if (*p1 != *p2)
            return *p1 - *p2;
        p1++;
        p2++;
    }
    return 0;
}

/* Memory search function */
void* memchr(const void* ptr, int value, size_t num) {
    const unsigned char* p = (const unsigned char*)ptr;
    while (num--) {
        if (*p == (unsigned char)value)
            return (void*)p;
        p++;
    }
    return NULL;
}

/* Zero memory */
void bzero(void* ptr, size_t num) {
    memset(ptr, 0, num);
}

/* ASCII to integer */
int atoi(const char* str) {
    int result = 0;
    int sign = 1;
    
    /* Skip whitespace */
    while (*str == ' ' || *str == '\t' || *str == '\n' || *str == '\r')
        str++;
    
    /* Handle sign */
    if (*str == '-') {
        sign = -1;
        str++;
    } else if (*str == '+') {
        str++;
    }
    
    /* Convert digits */
    while (*str >= '0' && *str <= '9') {
        result = result * 10 + (*str - '0');
        str++;
    }
    
    return sign * result;
}

/* Integer to string conversion */
char* itoa(int value, char* str, int base) {
    char* ptr = str;
    char* ptr1 = str;
    char tmp_char;
    int tmp_value;
    
    /* Check for supported base */
    if (base < 2 || base > 36) {
        *str = '\0';
        return str;
    }
    
    /* Handle negative numbers for base 10 */
    if (value < 0 && base == 10) {
        *ptr++ = '-';
        value = -value;
        ptr1++;
    }
    
    /* Convert to string (in reverse) */
    do {
        tmp_value = value;
        value /= base;
        *ptr++ = "0123456789abcdefghijklmnopqrstuvwxyz"[tmp_value - value * base];
    } while (value);
    
    /* Null terminate */
    *ptr-- = '\0';
    
    /* Reverse string */
    while (ptr1 < ptr) {
        tmp_char = *ptr;
        *ptr-- = *ptr1;
        *ptr1++ = tmp_char;
    }
    
    return str;
}

/* Unsigned integer to string */
char* utoa(unsigned int value, char* str, int base) {
    char* ptr = str;
    char* ptr1 = str;
    char tmp_char;
    unsigned int tmp_value;
    
    /* Check for supported base */
    if (base < 2 || base > 36) {
        *str = '\0';
        return str;
    }
    
    /* Convert to string (in reverse) */
    do {
        tmp_value = value;
        value /= base;
        *ptr++ = "0123456789abcdefghijklmnopqrstuvwxyz"[tmp_value - value * base];
    } while (value);
    
    /* Null terminate */
    *ptr-- = '\0';
    
    /* Reverse string */
    while (ptr1 < ptr) {
        tmp_char = *ptr;
        *ptr-- = *ptr1;
        *ptr1++ = tmp_char;
    }
    
    return str;
}

/* Character classification functions */
int isalpha(int c) {
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}

int isdigit(int c) {
    return (c >= '0' && c <= '9');
}

int isalnum(int c) {
    return (isalpha(c) || isdigit(c));
}

int isspace(int c) {
    return (c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v');
}

int isprint(int c) {
    return (c >= 32 && c <= 126);
}

int tolower(int c) {
    if (c >= 'A' && c <= 'Z')
        return c + ('a' - 'A');
    return c;
}

int toupper(int c) {
    if (c >= 'a' && c <= 'z')
        return c - ('a' - 'A');
    return c;
}

/* String reverse */
void strrev(char* str) {
    if (!str || !*str)
        return;
    
    size_t len = strlen(str);
    for (size_t i = 0; i < len / 2; i++) {
        char temp = str[i];
        str[i] = str[len - 1 - i];
        str[len - 1 - i] = temp;
    }
}

/* Helper function for number formatting */
void int_to_string(int value, char* buffer, int base) {
    itoa(value, buffer, base);
}

void uint_to_string(unsigned int value, char* buffer, int base) {
    utoa(value, buffer, base);
}

void hex_to_string(unsigned int value, char* buffer, bool uppercase) {
    const char* hex_chars = uppercase ? "0123456789ABCDEF" : "0123456789abcdef";
    buffer[0] = '0';
    buffer[1] = 'x';
    
    for (int i = 7; i >= 0; i--) {
        buffer[2 + (7 - i)] = hex_chars[(value >> (i * 4)) & 0xF];
    }
    buffer[10] = '\0';
}