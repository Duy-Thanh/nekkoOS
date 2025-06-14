#ifndef TYPES_H
#define TYPES_H

/* Basic integer types for 32-bit systems */
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

/* Size and pointer types */
typedef uint32_t           size_t;
typedef int32_t            ssize_t;
typedef uint32_t           uintptr_t;
typedef int32_t            intptr_t;

/* Boolean type */
typedef uint8_t            bool;
#define true               1
#define false              0

/* NULL pointer */
#ifndef NULL
#define NULL               ((void*)0)
#endif

/* Size limits */
#define SIZE_MAX           ((size_t)-1)

/* Common macros */
#define PACKED             __attribute__((packed))
#define ALIGN(x)           __attribute__((aligned(x)))
#define NORETURN           __attribute__((noreturn))
#define UNUSED             __attribute__((unused))

/* Bit manipulation macros */
#define BIT(n)             (1U << (n))
#define SET_BIT(x, n)      ((x) |= BIT(n))
#define CLEAR_BIT(x, n)    ((x) &= ~BIT(n))
#define TOGGLE_BIT(x, n)   ((x) ^= BIT(n))
#define CHECK_BIT(x, n)    (((x) & BIT(n)) != 0)

/* Memory alignment macros */
#define ALIGN_UP(x, a)     (((x) + (a) - 1) & ~((a) - 1))
#define ALIGN_DOWN(x, a)   ((x) & ~((a) - 1))
#define IS_ALIGNED(x, a)   (((x) & ((a) - 1)) == 0)

/* Min/Max macros */
#define MIN(a, b)          ((a) < (b) ? (a) : (b))
#define MAX(a, b)          ((a) > (b) ? (a) : (b))

/* Array size macro */
#define ARRAY_SIZE(arr)    (sizeof(arr) / sizeof((arr)[0]))

/* Offset of field in structure */
#define OFFSETOF(type, member) ((size_t) &((type*)0)->member)

/* Container of macro */
#define CONTAINER_OF(ptr, type, member) \
    ((type*)((char*)(ptr) - OFFSETOF(type, member)))

#endif /* TYPES_H */