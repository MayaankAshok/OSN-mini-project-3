#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

int
main(int argc, char *argv[]) {
    int x1= 1;
    if (fork()>0){
        x1 = 2;
    }
    else{
        x1 = 3;
        exit(0);
    }
    printf(">>>>%d\n", x1);
    exit(0);
}