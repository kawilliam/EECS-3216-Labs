/**
 * ADC module implementation for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #include <stdio.h>
 #include <math.h>
 #include "pico/stdlib.h"
 #include "hardware/adc.h"
 #include "hardware/irq.h"
 #include "adc.h"
 
 /**
  * Initialize ADC module
  * - Configures ADC for proximity sensor reading
  */
 void initialize_adc(void) {
     // Initialize ADC hardware (SDK function)
     adc_init();
     
     // Set up GPIO26 (ADC0) for proximity sensor
     adc_gpio_init(ADC_PIN_PROXIMITY);
     
     // Select ADC input channel
     adc_select_input(ADC_CHANNEL_PROXIMITY);
     
     printf("ADC initialized on GPIO%d (ADC channel %d)\n", 
            ADC_PIN_PROXIMITY, ADC_CHANNEL_PROXIMITY);
 }
 
 /**
  * Start continuous ADC conversion
  * This function initiates continuous ADC reading without interrupts
  * The actual readings are done in the timer callback (main.c)
  */
 void adc_start_continuous(void) {
     // Select ADC input 0 (GPIO26)
     adc_select_input(ADC_CHANNEL_PROXIMITY);
     
     // We don't use FIFO or interrupts in this implementation
     // The readings are done by timer-triggered polling
 }
 
 /**
  * Read proximity sensor value
  * 
  * Returns:
  * - ADC value from proximity sensor (0-4095 for 12-bit ADC)
  */
 uint16_t adc_read_proximity(void) {
     // Make sure we're on the right input
     adc_select_input(ADC_CHANNEL_PROXIMITY);
     
     // Perform ADC conversion and return the result
     return adc_read();
 }
 
 /**
  * Convert ADC value to distance (cm)
  * This function is specifically for Sharp GP2D12 IR Range Finder
  * Formula based on datasheet curve: Distance = A * (ADC_Value ^ B)
  * 
  * Parameters:
  * - adc_value: ADC reading (0-4095 for 12-bit ADC)
  * 
  * Returns:
  * - Distance in centimeters
  */
 float adc_convert_to_distance(uint16_t adc_value) {
     // Avoid division by zero or very small values
     if (adc_value < 80) return 80.0;  // Maximum range
     
     // Map 12-bit ADC value (0-4095) to the sensor's voltage range
     // Then calculate distance using the formula: Distance = A * (ADC_Value ^ B)
     // Note: For a proper implementation, use a lookup table or a more accurate formula
     // This is a simplified calculation and might need calibration
     float voltage = (float)adc_value * 3.3f / 4096.0f;
     return ADC_DISTANCE_CONSTANT_A * pow(voltage, ADC_DISTANCE_CONSTANT_B);
 }