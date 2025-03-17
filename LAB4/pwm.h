/**
 * PWM module header file for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #ifndef PWM_H
 #define PWM_H
 
 #include "pico/stdlib.h"
 #include "hardware/pwm.h"
 
 // PWM pin definitions
 #define PWM_PIN_MOTOR          0    // GPIO0 for motor control
 #define PWM_PIN_SERVO          1    // GPIO1 for servo control
 
 // PWM duty cycle constants
 #define PWM_MIN_DUTY           0
 #define PWM_MAX_DUTY           65535  // 16-bit PWM resolution (0-65535)
 
 // PWM frequency
 #define PWM_FREQ_HZ            25000   // 25 kHz for motor
 #define SERVO_PWM_FREQ_HZ      50      // 50 Hz for servo
 
 // Servo pulse width in μs (at 50Hz, period = 20ms = 20000μs)
 #define SERVO_MIN_PULSE        1000    // 1.0ms pulse (0 degrees)
 #define SERVO_MAX_PULSE        2000    // 2.0ms pulse (180 degrees)
 
 // Soft start/stop parameters
 #define SOFT_START_INITIAL_DUTY 6553   // Initial duty cycle (10%)
 #define DUTY_CYCLE_INCREMENT    655    // Increment value (1% per step)
 
 // Function prototypes
 void my_pwm_init(void);
 void pwm_set_duty_cycle(uint8_t slice_num, uint16_t duty_cycle);
 uint16_t pwm_get_duty_cycle(uint8_t slice_num);
 
 // Functions to get PWM slice and channel numbers
 uint8_t pwm_get_motor_slice(void);
 uint8_t pwm_get_motor_chan(void);
 uint8_t pwm_get_servo_slice(void);
 uint8_t pwm_get_servo_chan(void);
 
 #endif /* PWM_H */