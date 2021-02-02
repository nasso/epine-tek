#include "my.h"

int main(int argc, char** argv)
{
    my_putstr("Welcome to Epine!\n");
    for (int i = 1; i < argc; i++) {
        my_printf("%d: %s\n", i, argv[i]);
    }
    return (0);
}
