
#include <stdio.h>
#include <pico/stdlib.h>
#include <pico/time.h>
#include "hardware/pwm.h"
#include "hardware/adc.h"
#include "hardware/irq.h"
#include "hardware/timer.h"

#include "pwm.h"
#include "adc.h"
#include "servo.h"

volatile enum {
    MOTOR_IDLE,
    MOTOR_STARTING,
    MOTOR_RUNNING,
    MOTOR_STOPPING
} motor_state = MOTOR_IDLE;

volatile uint16_t current_duty_cycle = 0;

volatile uint16_t proximity_value = 0;
volatile bool object_detected = false;

#define PROXIMITY_NEAR_THRESHOLD 2000    // Object is close (ADC value)
#define PROXIMITY_FAR_THRESHOLD  1000    // Object is far (ADC value)

void setup(void);
bool timer_callback(struct repeating_timer *t);

int main()
{
    setup();
    
    printf("EECS3216 Lab4 - Soft Start/Stop via PWM\n");
    printf("Using Raspberry Pi Pico 2W\n\n");
    
    // Main program loop
    while (true) {
        // Main processing happens in interrupts
        // This loop just handles state transitions
        
        // Process proximity sensor data
        if (object_detected && motor_state == MOTOR_IDLE) {
            // Object detected and motor is idle, start soft start sequence
            printf("Object detected - Starting motor\n");
            motor_state = MOTOR_STARTING;
        } else if (!object_detected && motor_state == MOTOR_RUNNING) {
            // Object no longer detected and motor is running, start soft stop sequence
            printf("Object no longer detected - Stopping motor\n");
            motor_state = MOTOR_STOPPING;
        }
        
        // Optional: Sleep to reduce CPU usage
        sleep_ms(10);
    }
    
    return 0;
}

void setup(void) {
    // Initialize stdio
    stdio_init_all();
    
    // Initialize PWM for motor control
    my_pwm_init();
    
    // Initialize ADC for proximity sensor
    initialize_adc();
    
    // Initialize servo
    servo_init();
    
    // Add a repeating timer for soft start/stop control
    // 10ms interval (100Hz) for duty cycle updates
    struct repeating_timer timer;
    add_repeating_timer_ms(10, timer_callback, NULL, &timer);
    
    // Set initial motor state
    motor_state = MOTOR_IDLE;
    current_duty_cycle = 0;
    pwm_set_duty_cycle(pwm_get_motor_slice(), 0);
    
    // Set initial servo position (0 degrees)
    servo_set_position(0);
    
    // Start ADC conversions
    adc_start_continuous();
}

bool timer_callback(struct repeating_timer *t) {
    // No need to track time in this implementation
    
    // Handle different motor states and adjust PWM duty cycle
    switch (motor_state) {
        case MOTOR_STARTING:
            // Soft start - gradually increase duty cycle
            if (current_duty_cycle < PWM_MAX_DUTY) {
                // Check if adding increment would exceed max
                if ((PWM_MAX_DUTY - current_duty_cycle) <= DUTY_CYCLE_INCREMENT) {
                    current_duty_cycle = PWM_MAX_DUTY;
                } else {
                    current_duty_cycle += DUTY_CYCLE_INCREMENT;
                }
                pwm_set_duty_cycle(pwm_get_motor_slice(), current_duty_cycle);
            } else {
                // Reached maximum duty cycle, transition to RUNNING state
                motor_state = MOTOR_RUNNING;
                printf("Motor at full speed\n");
            }
            break;
            
        case MOTOR_STOPPING:
            // Soft stop - gradually decrease duty cycle
            if (current_duty_cycle > PWM_MIN_DUTY) {
                if (current_duty_cycle < DUTY_CYCLE_INCREMENT) {
                    current_duty_cycle = 0;
                } else {
                    current_duty_cycle -= DUTY_CYCLE_INCREMENT;
                }
                pwm_set_duty_cycle(pwm_get_motor_slice(), current_duty_cycle);
            } else {
                // Reached minimum duty cycle, transition to IDLE state
                motor_state = MOTOR_IDLE;
                printf("Motor stopped\n");
            }
            break;
            
        case MOTOR_IDLE:
        case MOTOR_RUNNING:
            // Nothing to adjust in these states
            break;
    }
    
    // Update proximity state based on ADC readings
    proximity_value = adc_read_proximity();
    
    // Determine if object is detected based on thresholds with hysteresis
    if (proximity_value >= PROXIMITY_NEAR_THRESHOLD) {
        // Object is detected (close enough)
        object_detected = true;
    } else if (proximity_value <= PROXIMITY_FAR_THRESHOLD) {
        // Object is too far
        object_detected = false;
    }
    // If between thresholds, maintain previous state (hysteresis)
    
    // If object is detected, update servo position
    if (object_detected) {
        servo_set_position(90);  // Move to 90 degrees when object detected
    } else {
        servo_set_position(0);   // Move to 0 degrees when no object
    }
    
    // Return true to keep the timer running
    return true;
}