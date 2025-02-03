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
    while (!stdio_usb_connected()) {
        sleep_ms(100);
    }
    printf("Program Start\n");
    

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
        if (first_num > 0) {
            currentState = FIRST_NUM;
        } else {
            printf("Invalid input.\n");
        }
    }
}

void handleFirstNumState() {
    printf("\nEnter the first number(or '0' to reset):\n");
    if (scanf("%d", &first_num) == 1) {
        if (first_num > 0) {
            product = first_num;
            currentState = NEXT_NUM;
        } else {
            currentState = IDLE;
        }
    }
}

void handleNextNumState() {
    printf("\nThe current product is %d\n", product);
    printf("Enter the next number(or '0' to reset):\n");
    if (scanf("%d", &next_num) == 1) {
        if (next_num > 0) {
            product *= next_num;
            if (product > 9999) {
                currentState = ERROR;
            }
        } else {
            currentState = IDLE;
        }
    }
    
}

void handleErrorState() {
    printf("\nOVERFLOW ERROR ENTER '0' TO RESET:\n");
    if (scanf("%d", &first_num) == 1) {
        if (first_num == 0) {
            currentState = IDLE;
        } else {
            printf("\nINVALID INPUT\n");
        }
    }
}