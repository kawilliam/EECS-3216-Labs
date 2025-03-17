/**
 * lab3calculator.c - Calculator implementation for Raspberry Pi Pico
 * 
 * This file needs to be modified slightly to work with the test harness:
 * - Add include guards
 * - Guard the main function with #ifndef CALCULATOR_TEST_MODE
 */

 #ifndef CALCULATOR_H
 #define CALCULATOR_H
 
 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include "pico/stdlib.h"
 #include "hardware/gpio.h"
 #include "pico/time.h"
 #include "calculator_types.h"
 
 // Keypad configuration
 #define ROWS 4
 #define COLS 4
 
 // 7-segment display configuration (using common cathode display)
 #define NUM_DIGITS 4                          // Number of 7-segment digits
 
 #ifndef CALCULATOR_TEST_MODE
 // Only define these variables if not in test mode
 const uint ROW_PINS[ROWS] = {2, 3, 4, 5};
 const uint COL_PINS[COLS] = {6, 7, 8, 9};
 const uint SEG_PINS[7] = {10, 11, 12, 13, 14, 15, 16};
 const uint DIGIT_PINS[NUM_DIGITS] = {17, 18, 19, 20};
 const char KEYMAP[ROWS][COLS] = {
     {'1', '2', '3', 'A'},
     {'4', '5', '6', 'B'},
     {'7', '8', '9', 'C'},
     {'*', '0', '#', 'D'}
 };
 const uint8_t SEGMENT_PATTERNS[12] = {
     0b1111110, // 0
     0b0110000, // 1
     0b1101101, // 2
     0b1111001, // 3
     0b0110011, // 4
     0b1011011, // 5
     0b1011111, // 6
     0b1110000, // 7
     0b1111111, // 8
     0b1111011, // 9
     0b0000001, // - (minus sign)
     0b1001111  // E (error)
 };
 #else
 // In test mode, these are declared as extern 
 extern const uint ROW_PINS[ROWS];  // GPIO pins connected to rows
 extern const uint COL_PINS[COLS];  // GPIO pins connected to columns
 extern const uint SEG_PINS[7];     // A, B, C, D, E, F, G segments
 extern const uint DIGIT_PINS[NUM_DIGITS];     // Common cathode pins for each digit
 extern const char KEYMAP[ROWS][COLS];
 extern const uint8_t SEGMENT_PATTERNS[12];
 #endif
 
 // Calculator states and operator types are defined in calculator_types.h
 
 // Global variables
 CalcState currentState = IDLE;
 OperatorType currentOperator = OP_NONE;
 int firstNumber = 0;
 int secondNumber = 0;
 int result = 0;
 int currentDigit = 0;
 bool negativeResult = false;
 uint32_t lastDebounceTime = 0;
 uint32_t debounceDelay = 50; // 50ms debounce delay
 int digitValuesToDisplay[NUM_DIGITS] = {0, 0, 0, 0};
 bool displayRefreshNeeded = true;
 
 // Function prototypes
 char scanKeypad();
 void updateDisplay();
 void refreshDisplay();
 void processKey(char key);
 void calculateResult();
 void setDisplayNumber(int number);
 void initHardware();
 void setErrorDisplay();
 
 // Calculate the result based on operator and operands
 void calculateResult() {
     switch (currentOperator) {
         case OP_ADD:
             result = firstNumber + secondNumber;
             break;
             
         case OP_SUBTRACT:
             result = firstNumber - secondNumber;
             if (result < 0) {
                 negativeResult = true;
                 result = -result;
             } else {
                 negativeResult = false;
             }
             break;
             
         case OP_MULTIPLY:
             result = firstNumber * secondNumber;
             break;
             
         default:
             result = 0;
             break;
     }
     
     // Check for overflow
     if (result > 9999) {
         currentState = ERROR;
         setErrorDisplay();
     }
 }
 
 // Process a key press based on current state
 void processKey(char key) {
     // Numbers 0-9
     if (key >= '0' && key <= '9') {
         int digit = key - '0';
         
         switch (currentState) {
             case IDLE:
                 firstNumber = digit;
                 currentState = FIRST_NUM;
                 break;
                 
             case FIRST_NUM:
                 // Append digit to first number
                 firstNumber = firstNumber * 10 + digit;
                 // Check for overflow
                 if (firstNumber > 9999) {
                     currentState = ERROR;
                     setErrorDisplay();
                 }
                 break;
                 
             case OP_SELECTED:
                 secondNumber = digit;
                 currentState = SECOND_NUM;
                 break;
                 
             case SECOND_NUM:
                 // Append digit to second number
                 secondNumber = secondNumber * 10 + digit;
                 // Check for overflow
                 if (secondNumber > 9999) {
                     currentState = ERROR;
                     setErrorDisplay();
                 }
                 break;
                 
             case RESULT:
                 // Clear previous calculation and start new
                 firstNumber = digit;
                 secondNumber = 0;
                 currentOperator = OP_NONE;
                 currentState = FIRST_NUM;
                 break;
                 
             case ERROR:
                 // Reset calculator on any number after error
                 currentState = IDLE;
                 firstNumber = digit;
                 secondNumber = 0;
                 currentOperator = OP_NONE;
                 currentState = FIRST_NUM;
                 break;
         }
         
         // Update display
         if (currentState == FIRST_NUM) {
             setDisplayNumber(firstNumber);
         } else if (currentState == SECOND_NUM) {
             setDisplayNumber(secondNumber);
         }
     } 
     // Operation keys
     else if (key == 'A' || key == 'B') {
         if (currentState == FIRST_NUM || currentState == RESULT) {
             // Set operator
             if (key == 'A') currentOperator = OP_ADD;
             else if (key == 'B') currentOperator = OP_MULTIPLY;
             
             currentState = OP_SELECTED;
         }
     }
     // Equal key
     else if (key == 'D') {
         if (currentState == SECOND_NUM) {
             calculateResult();
             setDisplayNumber(result);
             currentState = RESULT;
         }
     }
     // Clear key
     else if (key == 'C') {
         // Reset calculator
         currentState = IDLE;
         firstNumber = 0;
         secondNumber = 0;
         result = 0;
         currentOperator = OP_NONE;
         setDisplayNumber(0);
     }
     
     displayRefreshNeeded = true;
 }
 
 // Convert a number to individual digits for display
 void setDisplayNumber(int number) {
     // Clear the display buffer
     for (int i = 0; i < NUM_DIGITS; i++) {
         digitValuesToDisplay[i] = -1; // -1 means blank
     }
     
     // Special case for 0
     if (number == 0) {
         digitValuesToDisplay[NUM_DIGITS - 1] = 0;
         return;
     }
     
     // Extract digits
     int index = NUM_DIGITS - 1;
     while (number > 0 && index >= 0) {
         digitValuesToDisplay[index] = number % 10;
         number /= 10;
         index--;
     }
     
     // Handle negative numbers (display a minus sign)
     if (negativeResult && index >= 0) {
         digitValuesToDisplay[index] = 10; // Index 10 is the minus sign pattern
     }
 }
 
 // Set display to show error
 void setErrorDisplay() {
     // Display "E" on the leftmost digit
     for (int i = 0; i < NUM_DIGITS; i++) {
         digitValuesToDisplay[i] = -1; // Clear all digits
     }
     digitValuesToDisplay[0] = 11; // Error pattern (E)
 }
 
 // Scan the keypad with debouncing
 #ifndef CALCULATOR_TEST_MODE
 char scanKeypad() {
     char key = 0;
     uint32_t currentTime = to_ms_since_boot(get_absolute_time());
     
     // Only scan if debounce time has passed
     if (currentTime - lastDebounceTime < debounceDelay) {
         return 0;
     }
     
     // Scan the keypad
     for (int col = 0; col < COLS; col++) {
         // Set current column to low
         gpio_put(COL_PINS[col], 0);
         sleep_us(10); // Small delay for signal propagation
         
         // Check each row
         for (int row = 0; row < ROWS; row++) {
             if (gpio_get(ROW_PINS[row]) == 0) {
                 // Key is pressed
                 key = KEYMAP[row][col];
                 lastDebounceTime = currentTime;
                 
                 // Wait for key release (simple debounce)
                 while (gpio_get(ROW_PINS[row]) == 0) {
                     sleep_ms(10);
                 }
             }
         }
         
         // Set column back to high
         gpio_put(COL_PINS[col], 1);
     }
     
     return key;
 }
 #endif
 
 // Initialize all hardware peripherals
 void initHardware() {
     // Initialize row pins as inputs with pull-ups
     for (int i = 0; i < ROWS; i++) {
         gpio_init(ROW_PINS[i]);
         gpio_set_dir(ROW_PINS[i], GPIO_IN);
         gpio_pull_up(ROW_PINS[i]);
     }
     
     // Initialize column pins as outputs (initially high)
     for (int i = 0; i < COLS; i++) {
         gpio_init(COL_PINS[i]);
         gpio_set_dir(COL_PINS[i], GPIO_OUT);
         gpio_put(COL_PINS[i], 1);
     }
     
     // Initialize segment pins as outputs
     for (int i = 0; i < 7; i++) {
         gpio_init(SEG_PINS[i]);
         gpio_set_dir(SEG_PINS[i], GPIO_OUT);
         gpio_put(SEG_PINS[i], 0);
     }
     
     // Initialize digit select pins as outputs
     for (int i = 0; i < NUM_DIGITS; i++) {
         gpio_init(DIGIT_PINS[i]);
         gpio_set_dir(DIGIT_PINS[i], GPIO_OUT);
         gpio_put(DIGIT_PINS[i], 1); // Turn off all digits initially (common cathode logic)
     }
 }
 
 // Refresh the 7-segment display (to be called repeatedly)
 #ifndef CALCULATOR_TEST_MODE
 void refreshDisplay() {
     // Update each digit sequentially
     for (int digit = 0; digit < NUM_DIGITS; digit++) {
         // Turn off all digits first
         for (int i = 0; i < NUM_DIGITS; i++) {
             gpio_put(DIGIT_PINS[i], 1);
         }
         
         // Skip if this position is blank
         if (digitValuesToDisplay[digit] == -1) {
             continue;
         }
         
         // Get the pattern for this digit
         uint8_t pattern = SEGMENT_PATTERNS[digitValuesToDisplay[digit]];
         
         // Set segment pins
         for (int segment = 0; segment < 7; segment++) {
             gpio_put(SEG_PINS[segment], (pattern >> (6 - segment)) & 0x01);
         }
         
         // Turn on this digit
         gpio_put(DIGIT_PINS[digit], 0);
         
         // Small delay to make digit visible
         sleep_ms(2);
     }
     
     displayRefreshNeeded = true; // Keep refreshing the display
 }
 #endif
 
 // Only compile main function if not in test mode
 #ifndef CALCULATOR_TEST_MODE
 int main() 
 {
     // Initialize hardware
     stdio_init_all();
     initHardware();
     
     // Wait for USB connection (debug)
     while (!stdio_usb_connected()) {
         sleep_ms(100);
     }
     
     printf("Calculator Starting...\n");
     
     // Main loop
     while (true) {
         // Scan keypad
         char key = scanKeypad();
         
         // Process key if pressed
         if (key != 0) {
             printf("Key pressed: %c\n", key);
             processKey(key);
         }
         
         // Refresh display if needed
         if (displayRefreshNeeded) {
             refreshDisplay();
         }
     }
     
     return 0;
 }
 #endif // CALCULATOR_TEST_MODE
 
 #endif // CALCULATOR_H