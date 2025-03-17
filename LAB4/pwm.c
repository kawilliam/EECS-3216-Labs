/**
 * PWM module implementation for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #include <stdio.h>
 #include "pico/stdlib.h"
 #include "hardware/pwm.h"
 #include "hardware/clocks.h"
 #include "pwm.h"
 
 // Store the slice and channel numbers for our PWM channels
 static uint8_t motor_slice;
 static uint8_t motor_chan;
 static uint8_t servo_slice;
 static uint8_t servo_chan;
 
 // Since Pico SDK doesn't provide a way to get the current PWM level,
 // we'll track the values ourselves
 static uint16_t motor_duty_cycle = 0;
 static uint16_t servo_duty_cycle = SERVO_MIN_PULSE;
 
 /**
  * Initialize PWM module
  * - Configures PWM for motor and servo control
  */
 void my_pwm_init(void) {
     uint32_t clock_freq = clock_get_hz(clk_sys);
     
     // Configure PWM for motor control (GPIO0)
     gpio_set_function(PWM_PIN_MOTOR, GPIO_FUNC_PWM);
     motor_slice = pwm_gpio_to_slice_num(PWM_PIN_MOTOR);
     motor_chan = pwm_gpio_to_channel(PWM_PIN_MOTOR);
     
     // Configure PWM for servo control (GPIO1)
     gpio_set_function(PWM_PIN_SERVO, GPIO_FUNC_PWM);
     servo_slice = pwm_gpio_to_slice_num(PWM_PIN_SERVO);
     servo_chan = pwm_gpio_to_channel(PWM_PIN_SERVO);
     
     // Motor PWM configuration (25kHz frequency for efficient motor driving)
     // Calculate appropriate PWM wrap and divider values
     uint32_t motor_wrap = PWM_MAX_DUTY;  // 16-bit resolution
     float motor_divider = (float)clock_freq / (PWM_FREQ_HZ * motor_wrap);
     if (motor_divider < 1.0f) motor_divider = 1.0f;
     
     pwm_set_clkdiv(motor_slice, motor_divider);
     pwm_set_wrap(motor_slice, motor_wrap);
     pwm_set_chan_level(motor_slice, motor_chan, 0);
     motor_duty_cycle = 0;  // Initialize tracked value
     pwm_set_enabled(motor_slice, true);
     
     // Servo PWM configuration (50Hz standard servo frequency)
     // For servo, we need 50Hz with 1-2ms pulse width
     // Calculate appropriate PWM wrap and divider for SERVO_PWM_FREQ_HZ (50Hz)
     // Calculate to get exactly 50Hz with a wrap value that allows precise pulse widths
     uint32_t servo_wrap = 20000;  // Wrap value for 50Hz (with proper divider)
     float servo_divider = (float)clock_freq / (SERVO_PWM_FREQ_HZ * servo_wrap);
     if (servo_divider < 1.0f) servo_divider = 1.0f;
     
     pwm_set_clkdiv(servo_slice, servo_divider);
     pwm_set_wrap(servo_slice, servo_wrap);
     
     // Set initial servo position (1.0ms pulse = 0 degrees)
     // With 20000 wrap value, 1000 = 1ms pulse width (0 degrees)
     pwm_set_chan_level(servo_slice, servo_chan, SERVO_MIN_PULSE);
     servo_duty_cycle = SERVO_MIN_PULSE;  // Initialize tracked value
     pwm_set_enabled(servo_slice, true);
     
     printf("PWM initialized: Motor on GPIO%d (slice %d, chan %d), Servo on GPIO%d (slice %d, chan %d)\n", 
            PWM_PIN_MOTOR, motor_slice, motor_chan, 
            PWM_PIN_SERVO, servo_slice, servo_chan);
 }
 
 /**
  * Set PWM duty cycle
  * 
  * Parameters:
  * - slice_num: PWM slice number
  * - duty_cycle: Duty cycle value (0-65535)
  */
 void pwm_set_duty_cycle(uint8_t slice_num, uint16_t duty_cycle) {
     // Constrain duty cycle to valid range
     if (duty_cycle > PWM_MAX_DUTY) {
         duty_cycle = PWM_MAX_DUTY;
     }
     
     // Determine which channel to use based on the slice number
     uint8_t channel;
     if (slice_num == motor_slice) {
         channel = motor_chan;
     } else if (slice_num == servo_slice) {
         channel = servo_chan;
     } else {
         // Default to channel A if slice not recognized
         channel = PWM_CHAN_A;
     }
     
     // Set the duty cycle (PWM level)
     pwm_set_chan_level(slice_num, channel, duty_cycle);
     
     // Store the duty cycle value for later retrieval
     if (slice_num == motor_slice) {
         motor_duty_cycle = duty_cycle;
     } else if (slice_num == servo_slice) {
         servo_duty_cycle = duty_cycle;
     }
 }
 
 /**
  * Get current PWM duty cycle
  * 
  * Parameters:
  * - slice_num: PWM slice number
  * 
  * Returns:
  * - Current duty cycle value (0-65535)
  */
 uint16_t pwm_get_duty_cycle(uint8_t slice_num) {
     // Determine which channel to use based on the slice number
     uint8_t channel;
     if (slice_num == motor_slice) {
         channel = motor_chan;
     } else if (slice_num == servo_slice) {
         channel = servo_chan;
     } else {
         // Default to channel A if slice not recognized
         channel = PWM_CHAN_A;
     }
     
     // Return the stored duty cycle value
     if (slice_num == motor_slice) {
         return motor_duty_cycle;
     } else if (slice_num == servo_slice) {
         return servo_duty_cycle;
     } else {
         // Default return 0 if slice not recognized
         return 0;
     }
 }

/**
 * Get motor PWM slice number
 * 
 * Returns:
 * - PWM slice number for motor control
 */
uint8_t pwm_get_motor_slice(void) {
    return motor_slice;
}

/**
 * Get servo PWM slice number
 * 
 * Returns:
 * - PWM slice number for servo control
 */
uint8_t pwm_get_servo_slice(void) {
    return servo_slice;
}

/**
 * Get motor PWM channel number
 * 
 * Returns:
 * - PWM channel number for motor control
 */
uint8_t pwm_get_motor_chan(void) {
    return motor_chan;
}

/**
 * Get servo PWM channel number
 * 
 * Returns:
 * - PWM channel number for servo control
 */
uint8_t pwm_get_servo_chan(void) {
    return servo_chan;
}