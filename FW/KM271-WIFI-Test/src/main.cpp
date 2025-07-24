#include <Arduino.h>

#ifndef HW_REV
#warning HW_REV not defined! Please defined in platformio.ini with, e.g. for v0.0.6: -DHW_REV=000006. HW_REV set to default 0.0.6 => 000006
#define HW_REV 000006   // You can define it in platformio.ini, e.g.: build_flags = -DHW_REV=000006
#endif

gpio_num_t led1_pin = GPIO_NUM_21;
gpio_num_t led2_pin = GPIO_NUM_22;
#if HW_REV <= 000005
gpio_num_t led3_pin = GPIO_NUM_23;
#else  // HW_REV_PATCH >= 000006
gpio_num_t led3_pin = GPIO_NUM_17;
#endif
gpio_num_t led4_pin = GPIO_NUM_25;

void setup() {
  // put your setup code here, to run once:
  pinMode(led1_pin, OUTPUT);
  pinMode(led2_pin, OUTPUT);
  pinMode(led3_pin, OUTPUT);
  pinMode(led4_pin, OUTPUT);

  digitalWrite(led1_pin, HIGH);
  digitalWrite(led2_pin, HIGH);
  digitalWrite(led3_pin, HIGH);
  digitalWrite(led4_pin, HIGH);

  // Serial monitor setup
  Serial.begin(115200);
}

void loop() {
  delay(200);

  printf("KM271-Version: v%d.%d.%d", HW_REV / 10000, HW_REV / 100 % 100, HW_REV % 100);
  digitalWrite(led4_pin, HIGH);
  digitalWrite(led1_pin, LOW);

  delay(200);
  digitalWrite(led1_pin, HIGH);
  digitalWrite(led2_pin, LOW);

  delay(200);
  digitalWrite(led2_pin, HIGH);
  digitalWrite(led3_pin, LOW);
  
  delay(200);
  digitalWrite(led3_pin, HIGH);
  digitalWrite(led4_pin, LOW);

}