#ifndef CALCULATOR_TYPES_H
#define CALCULATOR_TYPES_H

// Calculator states
typedef enum {
    IDLE,           // Waiting for first input
    FIRST_NUM,      // Entering first number
    OP_SELECTED,    // Operator selected
    SECOND_NUM,     // Entering second number
    RESULT,         // Showing result
    ERROR           // Error state
} CalcState;

// Operator types
typedef enum {
    OP_NONE,
    OP_ADD,
    OP_SUBTRACT,
    OP_MULTIPLY
} OperatorType;

#endif // CALCULATOR_TYPES_H