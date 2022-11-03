#include <Arduino.h>

gpio_num_t led1_pin = GPIO_NUM_21;
gpio_num_t led2_pin = GPIO_NUM_22;
gpio_num_t led3_pin = GPIO_NUM_23;
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