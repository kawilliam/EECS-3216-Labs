/**
 * Servo motor control module implementation for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #include <stdio.h>
 #include "pico/stdlib.h"
 #include "hardware/pwm.h"
 #include "servo.h"
 #include "pwm.h"
 
 // We'll use the slice number from the PWM module
 
 /**
  * Initialize servo control
  * - PWM has already been initialized in pwm_init()
  */
 void servo_init(void) {
     // PWM is already configured in pwm_init()
     // We'll use the slice and channel numbers from the PWM module
     
     // Set initial position to 0 degrees
     servo_set_position(SERVO_MIN_POSITION);
     
     printf("Servo initialized on GPIO%d (PWM slice %d, channel %d)\n", 
            PWM_PIN_SERVO, pwm_get_servo_slice(), pwm_get_servo_chan());
 }
 
 /**
  * Set servo position
  * 
  * Parameters:
  * - degrees: Target position in degrees (0-180)
  */
 void servo_set_position(uint8_t degrees) {
     uint16_t pulse_width;
     uint8_t servo_slice = pwm_get_servo_slice();
     uint8_t servo_chan = pwm_get_servo_chan();
     
     // Constrain degrees to valid range
     if (degrees > SERVO_MAX_POSITION) {
         degrees = SERVO_MAX_POSITION;
     }
     
     // Calculate pulse width in microseconds based on position (linear mapping)
     // Map degrees (0-180) to pulse width (SERVO_MIN_PULSE - SERVO_MAX_PULSE)
     pulse_width = SERVO_MIN_PULSE + ((SERVO_MAX_PULSE - SERVO_MIN_PULSE) * degrees) / SERVO_MAX_POSITION;
     
     // Set PWM pulse width directly to ensure accurate timing
     pwm_set_chan_level(servo_slice, servo_chan, pulse_width);
 }