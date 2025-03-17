/**
 * ADC module header file for Raspberry Pi Pico
 * EECS3216 - Lab4
 */

 #ifndef ADC_H
 #define ADC_H
 
 #include "pico/stdlib.h"
 #include "hardware/adc.h"
 
 // ADC pin and channel definitions
 #define ADC_PIN_PROXIMITY     26    // GPIO26 (ADC0) for proximity sensor
 #define ADC_CHANNEL_PROXIMITY 0     // ADC channel 0
 
 // ADC result conversion constants
 // For Sharp GP2D12 IR Range Finder (based on datasheet)
 #define ADC_DISTANCE_CONSTANT_A  4780.0  // Constant A for distance calculation
 #define ADC_DISTANCE_CONSTANT_B  -1.1    // Constant B for distance calculation
 
 // Function prototypes
 void initialize_adc(void);
 void adc_start_continuous(void);
 uint16_t adc_read_proximity(void);
 float adc_convert_to_distance(uint16_t adc_value);
 
 #endif /* ADC_H */