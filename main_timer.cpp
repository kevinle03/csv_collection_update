#include <Adafruit_BNO08x.h>
#include <SPI.h>
#include "driver/timer.h"

#define BNO08X_CS 10
#define BNO08X_INT 9
#define BNO08X_RESET 5 

#define TIMER_DIVIDER         80
#define TIMER_TICKS_PER_US    (80000000 / 80 / 1000000)

Adafruit_BNO08x bno08x(BNO08X_RESET);
sh2_SensorValue_t sensorValue;

uint64_t last_time_us = 0;

void setReports(void);

void initHardwareTimer() {
    timer_config_t config = {
        .alarm_en = TIMER_ALARM_DIS,
        .counter_en = TIMER_PAUSE,
        .intr_type = TIMER_INTR_LEVEL,
        .counter_dir = TIMER_COUNT_UP,
        .auto_reload = TIMER_AUTORELOAD_DIS,
        .divider = TIMER_DIVIDER,
    };
    
    timer_init(TIMER_GROUP_0, TIMER_0, &config);
    timer_set_counter_value(TIMER_GROUP_0, TIMER_0, 0);
    timer_start(TIMER_GROUP_0, TIMER_0);
}

void setup(void) {
  Serial.begin(921600); 
  while (!Serial) delay(10); 

  initHardwareTimer();

  if (!bno08x.begin_SPI(BNO08X_CS, BNO08X_INT)) {
    Serial.println("Failed to find BNO08x chip");
    while (1) { delay(10); }
  }
  Serial.println("BNO08x Found over SPI");

  setReports();
}

void setReports(void) {
  if (!bno08x.enableReport(SH2_GAME_ROTATION_VECTOR)) {
    Serial.println("Could not enable game vector");
  }
  if (!bno08x.enableReport(SH2_LINEAR_ACCELERATION)) {
    Serial.println("Could not enable linear acceleration");
  }
}

void loop() {
  if (bno08x.wasReset()) {
    Serial.println("sensor was reset");
    setReports();
  }

  if (!bno08x.getSensorEvent(&sensorValue)) {
    return;
  }

  uint64_t current_time_us;
  timer_get_counter_value(TIMER_GROUP_0, TIMER_0, &current_time_us);
  
  uint64_t delta_t = current_time_us - last_time_us;
  last_time_us = current_time_us;

  Serial.print(current_time_us);
  Serial.print(",");
  Serial.print(delta_t);
  Serial.print(",");

  switch (sensorValue.sensorId) {
    case SH2_LINEAR_ACCELERATION:
      Serial.print("0,");
      Serial.print(sensorValue.un.linearAcceleration.x);
      Serial.print(",");
      Serial.print(sensorValue.un.linearAcceleration.y);
      Serial.print(",");
      Serial.println(sensorValue.un.linearAcceleration.z);
      break;

    case SH2_GAME_ROTATION_VECTOR:
      Serial.print("1,");
      Serial.print(sensorValue.un.gameRotationVector.real);
      Serial.print(",");
      Serial.print(-sensorValue.un.gameRotationVector.j);
      Serial.print(",");
      Serial.print(sensorValue.un.gameRotationVector.i);    
      Serial.print(",");
      Serial.println(sensorValue.un.gameRotationVector.k);
      break;
  }
}