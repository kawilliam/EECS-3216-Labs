/**
 * Servo motor control module header file for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #ifndef SERVO_H
 #define SERVO_H
 
 #include "pico/stdlib.h"
 #include "hardware/pwm.h"
 #include "pwm.h"  // Include for SERVO_MIN_PULSE and SERVO_MAX_PULSE constants
 
 // Servo position constants
 #define SERVO_MIN_POSITION  0    // 0 degrees
 #define SERVO_MAX_POSITION  180  // 180 degrees
 
 // NOTE: We're now using SERVO_MIN_PULSE and SERVO_MAX_PULSE from pwm.h
 
 // Function prototypes
 void servo_init(void);
 void servo_set_position(uint8_t degrees);
 
 #endif /* SERVO_H */