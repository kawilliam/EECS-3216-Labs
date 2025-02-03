#include <stdio.h>
#include "pico/stdlib.h"

typedef enum {
    IDLE,
    FIRST_NUM,
    NEXT_NUM,
    ERROR
} MultiplierState;

MultiplierState currentState = IDLE;
int first_num;
int next_num;
int product;

void handleIdleState();
void handleFirstNumState();
void handleNextNumState();
void handleErrorState();


int main()
{
    stdio_init_all();
    
    

    while (true) {
        switch (currentState) {
            case IDLE:
                handleIdleState();
                break;
            case FIRST_NUM:
                handleFirstNumState();
                break;
            case NEXT_NUM:
                handleNextNumState();
                break;
            case ERROR:
                handleErrorState();
                break;
            default:
                printf("Invalid state!\n");
                return 1;
        }
    }
}

void handleIdleState() {
    printf("This is a multiplier!\n------------------\n");
    printf("Enter '1' to start:\n");
    if (scanf("%d", &first_num) == 1) {
        while (getchar() != '\n');
        currentState = FIRST_NUM;
    }
}

void handleFirstNumState() {
    printf("Enter the first number:\n");
    scanf("%d", &first_num);
    while (getchar() != '\n');
    product = first_num;
    currentState = NEXT_NUM;
}

void handleNextNumState() {
    printf("The current product is %d\n", product);
    print("Enter the next number:\n");
    scanf("%d", &next_num);
    while (getchar() != '\n');
    product *= next_num;
    if (product > 9999) {
        currentState = ERROR;
    }
}

void handleErrorState() {
    printf("OVERFLOW ERROR ENTER '1' TO RESET");
    if (scanf("%d", &first_num) == 1) {
        while (getchar() != '\n');
        currentState = IDLE;
    }
}