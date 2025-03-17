/**
 * calculator_test.c - Test harness for calculator implementation
 *
 * This file provides testing functionality while using the actual
 * implementation from calculator.c
 */

 #include <stdio.h>
 #include <stdlib.h>
 #include <string.h>
 #include "pico/stdlib.h"
 #include "calculator_types.h"
 
 // Note: CALCULATOR_TEST_MODE is already defined via compiler flag in CMakeLists.txt

 // We need to declare these to avoid linker errors
 // since they're referenced in the original code
 const uint ROW_PINS[4] = {2, 3, 4, 5};
 const uint COL_PINS[4] = {6, 7, 8, 9};
 const uint SEG_PINS[7] = {10, 11, 12, 13, 14, 15, 16};
 const uint DIGIT_PINS[4] = {17, 18, 19, 20};
 const char KEYMAP[4][4] = {
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
 
 // Define this to indicate we're in test mode
 // Note: This is already defined via compiler flag in CMakeLists.txt, so we need to guard it
 #ifndef CALCULATOR_TEST_MODE
 #define CALCULATOR_TEST_MODE
 #endif

 // Forward declarations of functions and variables we need to test
 
 extern void processKey(char key);
 extern void calculateResult();
 extern int firstNumber;
 extern int secondNumber;
 extern int result;
 extern CalcState currentState;
 extern OperatorType currentOperator;
 extern int digitValuesToDisplay[4];
 // We'll override scanKeypad to simulate key presses
 char scanKeypad() {
     // This will be replaced by our test key sequence simulation
     return 0;
 }
 
 // Override refreshDisplay to track what would be displayed
 void refreshDisplay() {
     // This is overridden to do nothing in test mode
     // We'll inspect digitValuesToDisplay directly
 }
 
 // Include the calculator implementation
 // Note: You'll need to remove the main() function from the original file
 // or guard it with #ifndef CALCULATOR_TEST_MODE
 #include "lab3calculator.c"
 
 // Define test status reporting
 #define MAX_DISPLAY_DIGITS 4
 
 // Helper function to initialize calculator to known state
 void resetCalculator() {
     currentState = IDLE;
     currentOperator = OP_NONE;
     firstNumber = 0;
     secondNumber = 0;
     result = 0;
     for (int i = 0; i < MAX_DISPLAY_DIGITS; i++) {
         digitValuesToDisplay[i] = 0;
     }
 }
 
 // Helper function to simulate a sequence of keypresses
 void simulateKeySequence(const char* sequence) {
     printf("Simulating key sequence: %s\n", sequence);
     for (size_t i = 0; i < strlen(sequence); i++) {
         processKey(sequence[i]);
     }
 }
 
 // Helper function to check display value
 bool checkDisplayValue(int expected) {
     // Convert expected value to digits
     int expectedDigits[MAX_DISPLAY_DIGITS] = {-1, -1, -1, -1};
     
     if (expected == 0) {
         expectedDigits[MAX_DISPLAY_DIGITS - 1] = 0;
     } else {
         int tempVal = expected;
         int index = MAX_DISPLAY_DIGITS - 1;
         
         while (tempVal > 0 && index >= 0) {
             expectedDigits[index] = tempVal % 10;
             tempVal /= 10;
             index--;
         }
     }
     
     // Compare with actual display
     for (int i = 0; i < MAX_DISPLAY_DIGITS; i++) {
         if (digitValuesToDisplay[i] != expectedDigits[i]) {
             printf("Display mismatch at position %d: expected %d, got %d\n", 
                    i, expectedDigits[i], digitValuesToDisplay[i]);
             return false;
         }
     }
     
     return true;
 }
 
 // Test helper function to perform a test and validate result
 bool testOperation(const char* sequence, int expectedResult, int expectedState) {
     resetCalculator();
     simulateKeySequence(sequence);
     
     bool resultCorrect = (result == expectedResult);
     bool stateCorrect = (currentState == expectedState);
     bool displayCorrect = checkDisplayValue(expectedResult);
     
     printf("Test: %s\n", sequence);
     printf("  Result: %d (Expected: %d) - %s\n", result, expectedResult, resultCorrect ? "PASS" : "FAIL");
     printf("  State: %d (Expected: %d) - %s\n", currentState, expectedState, stateCorrect ? "PASS" : "FAIL");
     printf("  Display Check: %s\n", displayCorrect ? "PASS" : "FAIL");
     
     return resultCorrect && stateCorrect && displayCorrect;
 }
 
 // Test Cases
 void test_addition_simple() {
     bool passed = testOperation("2A3D", 5, RESULT);
     printf("\n");
     if (!passed) {
         printf("Simple addition test failed\n");
     }
 }
 
 void test_multiplication_simple() {
     bool passed = testOperation("4B5D", 20, RESULT);
     printf("\n");
     if (!passed) {
         printf("Simple multiplication test failed\n");
     }
 }
 
 void test_multi_digit_numbers() {
     bool passed = testOperation("123B45D", 5535, RESULT);
     printf("\n");
     if (!passed) {
         printf("Multi-digit number test failed\n");
     }
 }
 
 void test_overflow() {
     bool passed = testOperation("9999B9999D", 0, ERROR);
     // In overflow case, we don't check the display value as it should show an error
     printf("\n");
     if (!passed) {
         printf("Overflow test failed\n");
     }
 }
 
 void test_clear() {
     resetCalculator();
     simulateKeySequence("123A45C");
     
     bool passed = (currentState == IDLE && firstNumber == 0 && secondNumber == 0);
     printf("Clear Test: %s\n\n", passed ? "PASS" : "FAIL");
     if (!passed) {
         printf("Clear function test failed\n");
     }
 }
 
 void test_operation_after_result() {
     resetCalculator();
     simulateKeySequence("5B5D"); // 5 * 5 = 25
     simulateKeySequence("A5D");  // 25 + 5 = 30
     
     bool passed = (result == 30 && currentState == RESULT);
     printf("Operation After Result: %s\n\n", passed ? "PASS" : "FAIL");
     if (!passed) {
         printf("Operation after result test failed\n");
     }
 }
 
 // Main test runner
 int main() {
     stdio_init_all();
     
     // Wait for USB connection
     while (!stdio_usb_connected()) {
         sleep_ms(100);
     }
     
     printf("\n\n===== Calculator Test Suite =====\n\n");
     
     // Run all tests
     test_addition_simple();
     test_multiplication_simple();
     test_multi_digit_numbers();
     test_overflow();
     test_clear();
     test_operation_after_result();
     
     printf("\n===== Test Suite Complete =====\n");
     
     return 0;
 }