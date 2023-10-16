#include <stdio.h>
// #define DISPLAY

#ifdef DISPLAY
    #define Log(...) printf(__VA_ARGS__)
#else
    #define Log(...)
#endif
