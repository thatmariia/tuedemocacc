#include <Adafruit_NeoPixel.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "TRSensors.h"
#include <Wire.h>
//#include <FastPID.h>
#include <PulseInZero.h>

#define PWMA   6           //Left Motor Speed pin (ENA)
#define AIN2   A0          //Motor-L forward (IN2).
#define AIN1   A1          //Motor-L backward (IN1)
#define PWMB   5           //Right Motor Speed pin (ENB)
#define BIN1   A2          //Motor-R forward (IN3)
#define BIN2   A3          //Motor-R backward (IN4)
#define PIN 7
#define ECHO   2
#define TRIG   3
#define NUM_SENSORS 5
#define OLED_RESET 9
#define OLED_SA0   8
#define Addr 0x20


const int defaultSpeed = 120;   //100;

int va = defaultSpeed;
int vb = defaultSpeed;

int maximum = defaultSpeed;
int bt_maximum = defaultSpeed;

bool stopFlag = false;

byte value = 0;
//unsigned long lasttime = 0;

//int maximum = 170;
#define mappedConst 120.0//80.0//140.0

int speedToSetA = 0;
int speedToSetB = 0;

unsigned long lasttime_stop = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin();

  pinMode(PWMA,OUTPUT);                     
  pinMode(AIN2,OUTPUT);      
  pinMode(AIN1,OUTPUT);
  pinMode(PWMB,OUTPUT);       
  pinMode(AIN1,OUTPUT);     
  pinMode(AIN2,OUTPUT); 
	
  lineFollowingSetup();
  obstacleAvoidanceSetup();

  analogWrite(PWMA, va);
  analogWrite(PWMB, vb);
}


void loop() {
  obstacleControllerLoop();
  
  if (!stopFlag) {
    lineFollowingLoop();
  }

  handleSerialData();
 
  analogWrite(PWMA, speedToSetA);
  analogWrite(PWMB, speedToSetB);

  maximum = bt_maximum;
  
  if (stopFlag && (millis() - lasttime_stop > 50)) {
    stopFlag = false;
  }
}
